# --
# Copyright (C) 2012 Znuny GmbH, https://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package var::packagesetup::ZnunyDynamicFieldConfigItem;    ## no critic

use strict;
use warnings;

use utf8;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::DynamicField',
    'Kernel::System::GeneralCatalog',
    'Kernel::System::Log',
    'Kernel::System::ZnunyHelper',
);

use Kernel::System::VariableCheck qw(:all);

=head1 NAME

var::packagesetup::ZnunyDynamicFieldConfigItem - code to execute during package installation

=head1 SYNOPSIS

All code to execute during package installation

=head1 PUBLIC INTERFACE

=head2 new()

create an object

    my $CodeObject    = $Kernel::OM->Get('var::packagesetup::ZnunyDynamicFieldConfigItem');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

    $ZnunyHelperObject->_RebuildConfig();

    return $Self;
}

=head2 CodeInstall()

run the code install part

    my $Result = $CodeObject->CodeInstall();

=cut

sub CodeInstall {
    my ( $Self, %Param ) = @_;

    return 1;
}

=head2 CodeReinstall()

run the code reinstall part

    my $Result = $CodeObject->CodeReinstall();

=cut

sub CodeReinstall {
    my ( $Self, %Param ) = @_;

    return 1;
}

=head2 CodeUpgrade()

run the code upgrade part

    my $Result = $CodeObject->CodeUpgrade();

=cut

sub CodeUpgrade {
    my ( $Self, %Param ) = @_;

    return 1;
}

=head2 CodeUpgradeFromLowerThan602()

run the code upgrade part for package versions lower than 6.0.2

    my $Result = $CodeObject->CodeUpgradeFromLowerThan602();

=cut

sub CodeUpgradeFromLowerThan602 {
    my ( $Self, %Param ) = @_;

    my $ConfigObject       = $Kernel::OM->Get('Kernel::Config');
    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $LogObject          = $Kernel::OM->Get('Kernel::System::Log');

    my $UserID = 1;

    my $DeprecatedConfig = $ConfigObject->Get('ZnunyDynamicFieldConfigItem') // {};
    return 1 if !IsHashRefWithData($DeprecatedConfig);

    # Don't migrate deprecated SysConfig settings to dynamic field config
    # if config item linking is not enabled.
    return 1 if !$DeprecatedConfig->{TicketLink};

    # Fetch all dynamic fields of type ConfigItemDropdown and ConfigItemMultiselect
    # and object type 'Ticket', because linking is only supported for those.
    my $DynamicFields = $DynamicFieldObject->DynamicFieldListGet();
    my @DynamicFields = grep {
        $_->{FieldType} =~ m{\AConfigItem(Dropdown|Multiselect)\z}
            && $_->{ObjectType} eq 'Ticket'
    } @{$DynamicFields};

    return 1 if !@DynamicFields;

    # Migrate settings to existing dynamic field configs.
    my $ConfigItemLinkType    = $DeprecatedConfig->{LinkType} // 'RelevantTo';
    my $ConfigItemLinkSource  = 'ITSMConfigItem';
    my $ConfigItemLinkRemoval = 1;

    DYNAMICFIELD:
    for my $DynamicField (@DynamicFields) {

        # Ignore dynamic fields that somehow may have already set the link type.
        # This normally cannot happen.
        next DYNAMICFIELD if $DynamicField->{Config}->{ConfigItemLinkType};

        $DynamicField->{Config}->{ConfigItemLinkType}    = $ConfigItemLinkType;
        $DynamicField->{Config}->{ConfigItemLinkSource}  = $ConfigItemLinkSource;
        $DynamicField->{Config}->{ConfigItemLinkRemoval} = $ConfigItemLinkRemoval;

        my $DynamicFieldUpdated = $DynamicFieldObject->DynamicFieldUpdate(
            ID         => $DynamicField->{ID},
            Name       => $DynamicField->{Name},
            Label      => $DynamicField->{Label},
            FieldOrder => $DynamicField->{FieldOrder},
            FieldType  => $DynamicField->{FieldType},
            ObjectType => $DynamicField->{ObjectType},
            Config     => $DynamicField->{Config},
            ValidID    => $DynamicField->{ValidID},
            UserID     => $UserID,
        );
        next DYNAMICFIELD if $DynamicFieldUpdated;

        $LogObject->Log(
            Priority => 'error',
            Message  => "Dynamic field '$DynamicField->{Name}' (ID $DynamicField->{ID}) could not be updated.",
        );
    }

    return 1;
}

=head2 CodeUpgradeFromLowerThan608()

run the code upgrade part for package versions lower than 6.0.8

    my $Result = $CodeObject->CodeUpgradeFromLowerThan608();

=cut

sub CodeUpgradeFromLowerThan608 {
    my ( $Self, %Param ) = @_;

    my $ConfigObject         = $Kernel::OM->Get('Kernel::Config');
    my $DynamicFieldObject   = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $LogObject            = $Kernel::OM->Get('Kernel::System::Log');
    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

    my $UserID = 1;

    my $DeplStateNameByID = $GeneralCatalogObject->ItemList(
        Class => 'ITSM::ConfigItem::DeploymentState',
    );

    # Fetch all dynamic fields of type ConfigItemDropdown and ConfigItemMultiselect
    # and object type 'Ticket', because linking is only supported for those.
    my $DynamicFieldConfigs = $DynamicFieldObject->DynamicFieldListGet();
    my @DynamicFieldConfigs = grep {
        $_->{FieldType} =~ m{\AConfigItem(Dropdown|Multiselect)\z}
    } @{$DynamicFieldConfigs};

    return 1 if !@DynamicFieldConfigs;

    DYNAMICFIELDCONFIG:
    for my $DynamicFieldConfig (@DynamicFieldConfigs) {
        next DYNAMICFIELDCONFIG if !exists $DynamicFieldConfig->{Config}->{DeplStateIDs};

        my @DeplStates = grep { defined $_ }
            map { $DeplStateNameByID->{$_} }
            @{ $DynamicFieldConfig->{Config}->{DeplStateIDs} // [] };

        delete $DynamicFieldConfig->{Config}->{DeplStateIDs};
        $DynamicFieldConfig->{Config}->{DeplStates} = \@DeplStates;

        my $DynamicFieldConfigUpdated = $DynamicFieldObject->DynamicFieldUpdate(
            ID         => $DynamicFieldConfig->{ID},
            Name       => $DynamicFieldConfig->{Name},
            Label      => $DynamicFieldConfig->{Label},
            FieldOrder => $DynamicFieldConfig->{FieldOrder},
            FieldType  => $DynamicFieldConfig->{FieldType},
            ObjectType => $DynamicFieldConfig->{ObjectType},
            Config     => $DynamicFieldConfig->{Config},
            ValidID    => $DynamicFieldConfig->{ValidID},
            UserID     => $UserID,
        );
        next DYNAMICFIELDCONFIG if $DynamicFieldConfigUpdated;

        $LogObject->Log(
            Priority => 'error',
            Message =>
                "Config of dynamic field '$DynamicFieldConfig->{Name}' (ID $DynamicFieldConfig->{ID}) could not be updated.",
        );
    }

    return 1;
}

=head2 CodeUninstall()

run the code uninstall part

    my $Result = $CodeObject->CodeUninstall();

=cut

sub CodeUninstall {
    my ( $Self, %Param ) = @_;

    return 1;
}

1;
