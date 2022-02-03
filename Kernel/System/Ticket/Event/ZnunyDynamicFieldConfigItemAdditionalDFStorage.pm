# --
# Copyright (C) 2012-2021 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Ticket::Event::ZnunyDynamicFieldConfigItemAdditionalDFStorage;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::DynamicField',
    'Kernel::System::Log',
    'Kernel::System::ZnunyDynamicFieldConfigItem',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject                              = $Kernel::OM->Get('Kernel::System::Log');
    my $DynamicFieldObject                     = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $ZnunyDynamicFieldConfigItemObject = $Kernel::OM->Get('Kernel::System::ZnunyDynamicFieldConfigItem');

    NEEDED:
    for my $Needed (qw( Data Event Config UserID )) {
        next NEEDED if $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Need $Needed!"
        );
        return 1;
    }

    NEEDED:
    for my $Needed (qw( TicketID )) {
        next NEEDED if $Param{Data}->{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Need $Needed in Data!"
        );
        return 1;
    }

    my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
        Name => $Param{Data}->{FieldName},
    );
    return 1 if !IsHashRefWithData($DynamicFieldConfig);
    return 1 if $DynamicFieldConfig->{FieldType} ne 'ConfigItemDropdown'
        && $DynamicFieldConfig->{FieldType} ne 'ConfigItemMultiselect';

    return 1 if $DynamicFieldConfig->{ObjectType} ne 'Ticket';
    return 1 if !IsArrayRefWithData( $DynamicFieldConfig->{Config}->{AdditionalDFStorage} );

    my $ConfigItemIDs = $Param{Data}->{Value};    # can also be only one (scalar).
    return 1 if !defined $ConfigItemIDs;

    if ( !IsArrayRefWithData($ConfigItemIDs) ) {
        $ConfigItemIDs = [ $ConfigItemIDs, ];
    }

    my $AdditionalDFStorageData = $ZnunyDynamicFieldConfigItemObject->GetAdditionalDFStorageData(
        SourceDynamicFieldName => $Param{Data}->{FieldName},
        SelectedConfigItemIDs  => $ConfigItemIDs,
        StorageType            => 'Backend',
        UserID                 => $Param{UserID},
    );
    return 1 if !IsHashRefWithData($AdditionalDFStorageData);

    my $AdditionalDynamicFieldValuesStored = $ZnunyDynamicFieldConfigItemObject->StoreDynamicFieldValues(
        TicketID                => $Param{Data}->{TicketID},
        AdditionalDFStorageData => $AdditionalDFStorageData,
        UserID                  => $Param{UserID},
    );

    return if !$AdditionalDynamicFieldValuesStored;

    return 1;
}

1;
