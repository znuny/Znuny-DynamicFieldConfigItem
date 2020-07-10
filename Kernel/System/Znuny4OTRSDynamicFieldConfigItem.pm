# --
# Copyright (C) 2012-2020 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Znuny4OTRSDynamicFieldConfigItem;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::DateTime',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::ITSMConfigItem',
    'Kernel::System::Log',
);

use Kernel::System::VariableCheck qw(:all);

=head1 NAME

Kernel::System::Znuny4OTRSDynamicFieldConfigItem - Znuny4OTRSDynamicFieldConfigItem lib

=head1 SYNOPSIS

All Znuny4OTRSDynamicFieldConfigItem functions

=head1 PUBLIC INTERFACE

=head2 new()

    Don't use the constructor directly, use the ObjectManager instead:

    my $Znuny4OTRSDynamicFieldConfigItemObject = $Kernel::OM->Get('Kernel::System::Znuny4OTRSDynamicFieldConfigItem');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    my @ConfigItemStandardFields
        = qw(ConfigItemID Name ClassID Class DefinitionID DeplStateID DeplState InciStateID InciState);
    my %ConfigItemStandardFields = map { $_ => 1 } @ConfigItemStandardFields;
    $Self->{ConfigItemStandardFields} = \%ConfigItemStandardFields;

    return $Self;
}

# TODO: we should use the same naming like DF-LDAP (AutoFill) or standardize these

=head2 GetAdditionalDFStorageData()

    Returns data for dynamic fields that should be filled based on the source dynamic field
    configuration and the selected config items.

    my $AdditionalDFStorageData = $Znuny4OTRSDynamicFieldConfigItemObject->GetAdditionalDFStorageData(
        SourceDynamicFieldName => 'MyConfigItem',
        SelectedConfigItemIDs  => [ 45, 13, ],
        StorageType            => 'Frontend', # or 'Backend'
        UserID                 => 74,
    );

    Returns:

    {
        'MyDynamicField1' => $Value, # Can be anything. If the dynamic field is a multiselect, this is an array.
    },

=cut

sub GetAdditionalDFStorageData {
    my ( $Self, %Param ) = @_;

    my $LogObject          = $Kernel::OM->Get('Kernel::System::Log');
    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');

    NEEDED:
    for my $Needed (qw(SourceDynamicFieldName SelectedConfigItemIDs StorageType UserID)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
        Name => $Param{SourceDynamicFieldName},
    );
    return if !IsHashRefWithData($DynamicFieldConfig);

    return if $DynamicFieldConfig->{FieldType} ne 'ConfigItemDropdown'
        && $DynamicFieldConfig->{FieldType} ne 'ConfigItemMultiselect';

    # Only ticket dynamic fields are supported.
    return if $DynamicFieldConfig->{ObjectType} ne 'Ticket';

    # Evaluate selected config item IDs.
    return if !IsArrayRefWithData( $Param{SelectedConfigItemIDs} );
    my %SelectedConfigItemIDs = map { $_ => 1 }
        grep {
        defined $_
            && $_ =~ m{\A[1-9]\d*\z}
        }
        @{ $Param{SelectedConfigItemIDs} };
    my @SelectedConfigItemIDs = keys %SelectedConfigItemIDs;
    return if !@SelectedConfigItemIDs;

    # Evaluate additional dynamic field storage configs.
    my $AdditionalDFStorageConfigs = $DynamicFieldConfig->{Config}->{AdditionalDFStorage};
    return if !IsArrayRefWithData($AdditionalDFStorageConfigs);

    # Limit to those storage configs matching the given storage type.
    # Regex for storage type because the config value can also be 'FrontendBackend'.
    my @AdditionalDFStorageConfigs = grep { $_->{Type} =~ m{$Param{StorageType}} } @{$AdditionalDFStorageConfigs};

    #
    # Assemble data of config items.
    #
    my @ConfigItemData;

    CONFIGITEMID:
    for my $ConfigItemID (@SelectedConfigItemIDs) {
        my $ConfigItemData = $Self->_GetConfigItemData(
            ConfigItemID => $ConfigItemID,
            UserID       => $Param{UserID},
        );
        next CONFIGITEMID if !IsHashRefWithData($ConfigItemData);

        push @ConfigItemData, $ConfigItemData;
    }

    return {} if !@ConfigItemData;

    my $AdditionalDFStorageData = $Self->_GetAdditionalDFStorageData(
        ConfigItemData             => \@ConfigItemData,
        AdditionalDFStorageConfigs => \@AdditionalDFStorageConfigs,
    );

    return $AdditionalDFStorageData;
}

=head2 StoreDynamicFieldValues()

    Stores dynamic field values with given additional dynamic field storage data.

    my $StoredDynamicFields = $Znuny4OTRSDynamicFieldConfigItemObject->StoreDynamicFieldValues(
        TicketID                => 56,
        AdditionalDFStorageData => {
            # hash returned by GetAdditionalDFStorageData()
        },
        UserID => 213,
    );

    Returns array ref with names of dynamic fields that have been updated successfully.

=cut

sub StoreDynamicFieldValues {
    my ( $Self, %Param ) = @_;

    my $LogObject                 = $Kernel::OM->Get('Kernel::System::Log');
    my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    NEEDED:
    for my $Needed (qw(TicketID AdditionalDFStorageData UserID)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $AdditionalDFStorageData = $Param{AdditionalDFStorageData};
    return if !IsHashRefWithData($AdditionalDFStorageData);

    my @StoredDynamicFields;

    DYNAMICFIELDNAME:
    for my $DynamicFieldName ( sort keys %{$AdditionalDFStorageData} ) {
        next DYNAMICFIELDNAME if !exists $Param{AdditionalDFStorageData}->{$DynamicFieldName};

        my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
            Name => $DynamicFieldName,
        );
        next DYNAMICFIELDNAME if !IsHashRefWithData($DynamicFieldConfig);

        # Additional dynamic field storage is only supported for ticket dynamic fields.
        next DYNAMICFIELDNAME if $DynamicFieldConfig->{ObjectType} ne 'Ticket';

        my $ValueStored;
        if ( defined $Param{AdditionalDFStorageData}->{$DynamicFieldName} ) {
            $ValueStored = $DynamicFieldBackendObject->ValueSet(
                DynamicFieldConfig => $DynamicFieldConfig,
                ObjectID           => $Param{TicketID},
                Value              => $Param{AdditionalDFStorageData}->{$DynamicFieldName},
                UserID             => $Param{UserID},
            );
        }
        else {
            $ValueStored = $DynamicFieldBackendObject->ValueSet(
                DynamicFieldConfig => $DynamicFieldConfig,
                ObjectID           => $Param{TicketID},
                UserID             => $Param{UserID},
            );
        }

        next DYNAMICFIELDNAME if !$ValueStored;

        push @StoredDynamicFields, $DynamicFieldName;
    }

    return \@StoredDynamicFields;
}

=head2 _GetConfigItemData()

    Returns data of the last version in a sane form for the given config item ID.

    my $ConfigItemData = $Znuny4OTRSDynamicFieldConfigItemObject->_GetConfigItemData(
        ConfigItemID => 52,
        UserID       => 54,
    );

    Returns a hash reference.

=cut

sub _GetConfigItemData {
    my ( $Self, %Param ) = @_;

    my $ConfigItemObject = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my $LogObject        = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(ConfigItemID UserID)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $ConfigItemVersion = $ConfigItemObject->VersionGet(
        ConfigItemID => $Param{ConfigItemID},
        XMLDataGet   => 1,
    );
    return if !IsHashRefWithData($ConfigItemVersion);

    my %ConfigItemData;
    $ConfigItemData{XMLData} = {};
    if ( IsHashRefWithData( $ConfigItemVersion->{XMLData}->[1]->{Version}->[1] ) ) {
        $Self->_ParseXML2Data(
            %Param,
            Result          => $ConfigItemData{XMLData},
            Data            => $ConfigItemVersion->{XMLData}->[1]->{Version}->[1],
            XMLDataMultiple => 1,
        );
    }

    for my $Field ( sort keys %{ $Self->{ConfigItemStandardFields} } ) {
        $ConfigItemData{$Field} = $ConfigItemVersion->{$Field};
    }

    return \%ConfigItemData;
}

=head2 _GetAdditionalDFStorageData()

    Returns data which should be stored in additional dynamic fields for the given
    config item data.

    my $AdditionalDFStorageData = $Znuny4OTRSDynamicFieldConfigItemObject->_GetAdditionalDFStorageData(
        ConfigItemData => [
            {
                # Data returned by _GetConfigItemData()
            },
            {
                # Data returned by _GetConfigItemData()
            },
            # ...
        ],
        AdditionalDFStorageConfigs => [
            {
                DynamicFieldName => 'MyDynamicField',
                ConfigItemKey    => 'CPU::1',
                Type             => 'Frontend',
            },
            # ...
        ],
    );

    Returns hash with data to be stored in dynamic fields.
    Dynamic field name => value(s)

=cut

sub _GetAdditionalDFStorageData {
    my ( $Self, %Param ) = @_;

    my $LogObject          = $Kernel::OM->Get('Kernel::System::Log');
    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');

    NEEDED:
    for my $Needed (qw(ConfigItemData AdditionalDFStorageConfigs)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my %DynamicFieldValues;

    ADDITIONALDFSTORAGECONFIG:
    for my $AdditionalDFStorageConfig ( @{ $Param{AdditionalDFStorageConfigs} } ) {
        my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
            Name => $AdditionalDFStorageConfig->{DynamicField},
        );
        next ADDITIONALDFSTORAGECONFIG if !IsHashRefWithData($DynamicFieldConfig);

        # Only ticket dynamic fields are supported
        next ADDITIONALDFSTORAGECONFIG if $DynamicFieldConfig->{ObjectType} ne 'Ticket';

        my @ConfigItemFieldRawValues;

        CONFIGITEMDATA:
        for my $ConfigItemData ( @{ $Param{ConfigItemData} } ) {
            my $ConfigItemFieldRawValue;

            my @ConfigItemKeyParts = split '::', $AdditionalDFStorageConfig->{ConfigItemKey};

            CONFIGITEMKEYPART:
            for my $ConfigItemKeyPart (@ConfigItemKeyParts) {

                #
                # Config item key part is field index (e.g. 2)
                #
                if ( $ConfigItemKeyPart =~ m{\A\d+\z} ) {

                    # Index in config starts at 1 (e.g. CPU::1).
                    my $Index = $ConfigItemKeyPart - 1;

                    # Referencing an index on a non-array.
                    # Referencing an invalid index on an array.
                    if (
                        !IsArrayRefWithData($ConfigItemFieldRawValue)
                        || !exists $ConfigItemFieldRawValue->[$Index]
                        )
                    {
                        $ConfigItemFieldRawValue = undef;
                        next ADDITIONALDFSTORAGECONFIG;
                    }

                    $ConfigItemFieldRawValue = $ConfigItemFieldRawValue->[$Index];

                    next CONFIGITEMKEYPART;
                }

                #
                # Config item key part is field name (e.g. CPU)
                #

                # Standard config item field
                if ( $Self->{ConfigItemStandardFields}->{$ConfigItemKeyPart} ) {
                    $ConfigItemFieldRawValue = $ConfigItemData->{$ConfigItemKeyPart};

                    # Standard field: These are always scalars, so stop after first key part.
                    # Additional key parts would be wrong and will be ignored.
                    last CONFIGITEMKEYPART;
                }

                # Field in XML structure of config item, top level (e.g. NIC)
                if ( !defined $ConfigItemFieldRawValue ) {
                    next ADDITIONALDFSTORAGECONFIG
                        if !exists $ConfigItemData->{XMLData}->{$ConfigItemKeyPart};

                    $ConfigItemFieldRawValue = $ConfigItemData->{XMLData}->{$ConfigItemKeyPart};
                    next CONFIGITEMKEYPART;
                }

                # Field in XML structure of config item, sub level (e.g. NIC::1::IPAddress)
                next ADDITIONALDFSTORAGECONFIG if !IsHashRefWithData($ConfigItemFieldRawValue);
                next ADDITIONALDFSTORAGECONFIG if !exists $ConfigItemFieldRawValue->{$ConfigItemKeyPart};

                $ConfigItemFieldRawValue = $ConfigItemFieldRawValue->{$ConfigItemKeyPart};
            }

            next CONFIGITEMDATA if !defined $ConfigItemFieldRawValue;

            if ( IsArrayRefWithData($ConfigItemFieldRawValue) ) {
                CURRENTCONFIGITEMFIELDRAWVALUE:
                for my $CurrentConfigItemFieldRawValue ( @{$ConfigItemFieldRawValue} ) {
                    next CURRENTCONFIGITEMFIELDRAWVALUE if !IsHashRefWithData($CurrentConfigItemFieldRawValue);
                    next CURRENTCONFIGITEMFIELDRAWVALUE if !exists $CurrentConfigItemFieldRawValue->{Content};

                    push @ConfigItemFieldRawValues, $CurrentConfigItemFieldRawValue->{Content};
                }
            }
            elsif ( IsHashRefWithData($ConfigItemFieldRawValue) ) {
                if ( exists $ConfigItemFieldRawValue->{Content} ) {
                    push @ConfigItemFieldRawValues, $ConfigItemFieldRawValue->{Content};
                }
            }
            else {
                push @ConfigItemFieldRawValues, $ConfigItemFieldRawValue;
            }
        }

        next ADDITIONALDFSTORAGECONFIG if !@ConfigItemFieldRawValues;

        # Make raw values unique
        my %ConfigItemFieldRawValues = map { $_ => 1 } @ConfigItemFieldRawValues;
        @ConfigItemFieldRawValues = sort keys %ConfigItemFieldRawValues;

        my $DynamicFieldValue = $Self->_ConvertConfigItemFieldRawValuesToDynamicFieldValue(
            DynamicFieldType         => $DynamicFieldConfig->{FieldType},
            ConfigItemFieldRawValues => \@ConfigItemFieldRawValues,
        );

        next ADDITIONALDFSTORAGECONFIG if !defined $DynamicFieldValue;

        $DynamicFieldValues{ $AdditionalDFStorageConfig->{DynamicField} } = $DynamicFieldValue;
    }

    return \%DynamicFieldValues;
}

=head2 _ConvertConfigItemFieldRawValuesToDynamicFieldValue()

    Converts given raw values (which is always an array) to a value that can be given
    to the dynamic field method ValueSet.

    my $DynamicFieldValue = $Znuny4OTRSDynamicFieldConfigItemObject->_ConvertConfigItemFieldRawValuesToDynamicFieldValue(
        DynamicFieldType         => 'Multiselect',
        ConfigItemFieldRawValues => [
            # ...
        ],
    );

    Returns value for dynamic field method ValueSet.
    Returns nothing if value could not be converted.

=cut

sub _ConvertConfigItemFieldRawValuesToDynamicFieldValue {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    NEEDED:
    for my $Needed (qw(DynamicFieldType ConfigItemFieldRawValues)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $ConfigItemFieldRawValues = $Param{ConfigItemFieldRawValues};
    return if !IsArrayRefWithData($ConfigItemFieldRawValues);

    my $DynamicFieldType = $Param{DynamicFieldType};

    # Leave arrays is for multiselect. Don't check possible values of dynamic field because frontend
    # could have changed them anyways.
    return $ConfigItemFieldRawValues if $DynamicFieldType eq 'Multiselect';

    # Use first value for dropdown.
    return $ConfigItemFieldRawValues->[0] if $DynamicFieldType eq 'Dropdown';

    # Concatenate for text(area).
    if ( $DynamicFieldType =~ m{\AText(Area)?\z} ) {
        my $DynamicFieldValue = join ', ', @{$ConfigItemFieldRawValues};
        return $DynamicFieldValue;
    }

    # Add/remove time for Date(Time).
    # Only consider first value from config items.
    if ( $DynamicFieldType =~ m{\ADate(Time)?\z} ) {
        my $ConfigItemFieldRawValue = $ConfigItemFieldRawValues->[0];

        my $DateTimeObject = $Kernel::OM->Create(
            'Kernel::System::DateTime',
            ObjectParams => {
                String => $ConfigItemFieldRawValue,
                }
        );
        return if !$DateTimeObject;

        return $DateTimeObject->Format( Format => '%Y-%m-%d %H:%M:%S' ) if $DynamicFieldType eq 'DateTime';
        return $DateTimeObject->Format( Format => '%Y-%m-%d' );
    }

    return;
}

#
# Taken from Znuny4OTRS-Repo: Kernel::System::ZnunyHelper (8e336b82cc4e030fe48778e04c011c12e052397f)
#

=head2 _ParseXML2Data()

this is a internal function for _ITSMVersionGet to parse the additional data
stored in XMLData.

    my $Success = $ZnunyHelperObject->_ParseXML2Data(
        Parent          => $Identifier,          # optional: contains the field name of the parent xml
        Result          => $Result,              # contains the reference to the result hash
        Data            => $Data{$Field}->[1],   # contains the xml hash we want to parse
        XMLDataMultiple => 1,                    # default: 0, This option will return a more complex XMLData structure with multiple element data! Makes sense if you are using CountMin, CountMax etc..
    );

Returns:

    my $Success = 1;

=cut

sub _ParseXML2Data {
    my ( $Self, %Param ) = @_;

    my $Result          = $Param{Result};
    my $XMLDataMultiple = $Param{XMLDataMultiple};
    my $Parent          = $Param{Parent} || '';
    my %Data            = %{ $Param{Data} || {} };

    FIELD:
    for my $Field ( sort keys %Data ) {
        next FIELD if !IsArrayRefWithData( $Data{$Field} );

        if ($XMLDataMultiple) {
            $Result->{$Field} = [];

            for my $Index ( 1 .. $#{ $Data{$Field} } ) {
                my $Value = $Data{$Field}->[$Index]->{Content};

                my $CurrentResult = {};

                $Self->_ParseXML2Data(
                    %Param,
                    Parent => $Field,
                    Result => $CurrentResult,
                    Data   => $Data{$Field}->[$Index],
                );

                if ( defined $Value ) {
                    $CurrentResult->{Content} = $Value;

                    if ( keys %{$CurrentResult} ) {
                        push @{ $Result->{$Field} }, $CurrentResult;
                    }
                }
            }
        }
        else {
            my $Value = $Data{$Field}->[1]->{Content};

            next FIELD if !defined $Value;

            $Result->{$Field} = $Value;
        }
    }

    return 1;
}

1;
