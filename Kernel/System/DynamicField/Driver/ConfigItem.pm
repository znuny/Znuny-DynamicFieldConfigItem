# --
# Copyright (C) 2012-2019 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::DynamicField::Driver::ConfigItem;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

use mro 'c3';

our @ObjectDependencies = (
    'Kernel::System::GeneralCatalog',
    'Kernel::System::ITSMConfigItem',
);

sub ValueGet {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    return $Self->next::method(%Param);
}

sub ValueSet {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    return $Self->next::method(%Param);
}

sub ValueValidate {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    return $Self->next::method(%Param);
}

sub SearchSQLGet {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    return $Self->next::method(%Param);
}

sub SearchSQLOrderFieldGet {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    return $Self->next::method(%Param);
}

sub EditFieldRender {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    return $Self->next::method(%Param);
}

sub EditFieldValueGet {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    return $Self->next::method(%Param);
}

sub EditFieldValueValidate {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    return $Self->next::method(%Param);
}

sub DisplayValueRender {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    return $Self->next::method(%Param);
}

sub SearchFieldRender {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    return $Self->next::method(%Param);
}

sub SearchFieldValueGet {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    return $Self->next::method(%Param);
}

sub SearchFieldParameterBuild {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    return $Self->next::method(%Param);
}

sub StatsFieldParameterBuild {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    return $Self->next::method(%Param);
}

sub StatsSearchFieldParameterBuild {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    return $Self->next::method(%Param);
}

sub ReadableValueRender {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    return $Self->next::method(%Param);
}

sub TemplateValueTypeGet {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    return $Self->next::method(%Param);
}

sub RandomValueSet {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    return $Self->next::method(%Param);
}

sub ObjectMatch {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    return $Self->next::method(%Param);
}

sub HistoricalValuesGet {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    return $Self->next::method(%Param);
}

sub ValueLookup {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    return $Self->next::method(%Param);
}

sub BuildSelectionDataGet {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    return $Self->next::method(%Param);
}

sub ColumnFilterValuesGet {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    return $Self->next::method(%Param);
}

sub PossibleValuesGet {
    my ( $Self, %Param ) = @_;

    my $ConfigItemObject     = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

    my $Class = $Param{DynamicFieldConfig}->{Config}->{ConfigItemClass};
    return if !$Class;

    # check all CI classes
    my $HashRef = $GeneralCatalogObject->ItemList(
        Class => 'ITSM::ConfigItem::Class',
    );
    my %Classes = reverse %{ $HashRef || {} };
    return if !$Classes{$Class};

    my $ConfigItemListRef = [];

    # limit selectable config items to those which have one of the configured
    # deployment states
    my $DeplStateIDs = $Param{DynamicFieldConfig}->{Config}->{DeplStateIDs} // [];
    if ( IsArrayRefWithData($DeplStateIDs) ) {
        my $ConfigItemIDs = $ConfigItemObject->ConfigItemSearch(
            ClassIDs     => [ $Classes{$Class}, ],
            DeplStateIDs => $DeplStateIDs,
        );

        for my $ConfigItemID ( @{$ConfigItemIDs} ) {
            my $LastVersion = $ConfigItemObject->VersionGet(
                ConfigItemID => $ConfigItemID,
                XMLDataGet   => 0,
            );

            push @{$ConfigItemListRef}, $LastVersion;
        }
    }
    else {
        # get all config items of that class
        $ConfigItemListRef = $ConfigItemObject->ConfigItemResultList(
            ClassID => $Classes{$Class},
            Start   => 0,
            Limit   => 1_000_000,
        );
    }

    my %PossibleValues;
    CONFIGITEM:
    for my $ConfigItem ( @{ $ConfigItemListRef || {} } ) {
        $PossibleValues{ $ConfigItem->{ConfigItemID} } = $ConfigItem->{Name};
    }

    # Add empty value, none of the config item fields can have a default or pre-selected value
    # because the selectable values may change depending on deployment state.
    $PossibleValues{''} = '-';

    return \%PossibleValues;
}

1;
