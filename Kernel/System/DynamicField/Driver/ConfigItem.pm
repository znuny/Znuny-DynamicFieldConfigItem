# --
# Copyright (C) 2012-2017 Znuny GmbH, http://znuny.com/
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

    $Self->next::method(%Param);
}

sub ValueSet {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    $Self->next::method(%Param);
}

sub ValueIsDifferent {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    $Self->next::method(%Param);
}

sub ValueValidate {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    $Self->next::method(%Param);
}

sub EditFieldRender {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    $Self->next::method(%Param);
}

sub EditFieldValueGet {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    $Self->next::method(%Param);
}

sub EditFieldValueValidate {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    $Self->next::method(%Param);
}

sub DisplayValueRender {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    $Self->next::method(%Param);
}

sub SearchFieldParameterBuild {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    $Self->next::method(%Param);
}

sub StatsFieldParameterBuild {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    $Self->next::method(%Param);
}

sub ReadableValueRender {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    $Self->next::method(%Param);
}

sub TemplateValueTypeGet {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    $Self->next::method(%Param);
}

sub ObjectMatch {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    $Self->next::method(%Param);
}

sub HistoricalValuesGet {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    $Self->next::method(%Param);
}

sub ValueLookup {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    $Self->next::method(%Param);
}

sub BuildSelectionDataGet {
    my ( $Self, %Param ) = @_;

    $Param{DynamicFieldConfig}->{Config}->{PossibleValues} = $Self->PossibleValuesGet(%Param);

    $Self->next::method(%Param);
}

sub PossibleValuesGet {
    my ( $Self, %Param ) = @_;

    my $ConfigItemObject     = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

    # get config class
    my $Class = $Param{DynamicFieldConfig}->{Config}->{ConfigItemClass};
    return if !$Class;

    # check all ci classes
    my $HashRef = $GeneralCatalogObject->ItemList(
        Class => 'ITSM::ConfigItem::Class',
    );
    my %Classes = reverse %{ $HashRef || {} };

    # check if class exists
    return if !$Classes{$Class};

    # get all config items of that class
    my $ConfigItemListRef = $ConfigItemObject->ConfigItemResultList(
        ClassID => $Classes{$Class},
        Start   => 0,
        Limit   => 1_000_000,
    );

    # create possible values hash
    my %PossibleValues;
    CONFIGITEM:
    for my $ConfigItem ( @{ $ConfigItemListRef || {} } ) {
        $PossibleValues{ $ConfigItem->{ConfigItemID} } = $ConfigItem->{Name};
    }

    # return the possible values hash as a reference
    return \%PossibleValues;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
