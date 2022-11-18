# --
# Copyright (C) 2012-2022 Znuny GmbH, https://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminDynamicFieldConfigItem;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::DynamicField',
    'Kernel::System::GeneralCatalog',
    'Kernel::System::LinkObject',
    'Kernel::System::Valid',
    'Kernel::System::Web::Request',
);

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $Self = {%Param};
    bless( $Self, $Type );

    $Self->{ObjectTypeConfig} = $ConfigObject->Get('DynamicFields::ObjectType');
    $Self->{FieldTypeConfig}  = $ConfigObject->Get('DynamicFields::Driver') || {};

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    $LayoutObject->AddJSOnDocumentCompleteIfNotExists(
        Key  => 'AdminDynamicFieldConfigItem',
        Code => 'Core.Agent.Admin.ZnunyDynamicFieldConfigItem.Init();',
    );

    if ( $Self->{Subaction} eq 'Add' ) {
        return $Self->_Add(%Param);
    }
    elsif ( $Self->{Subaction} eq 'AddAction' ) {
        $LayoutObject->ChallengeTokenCheck();

        return $Self->_AddAction(%Param);
    }
    elsif ( $Self->{Subaction} eq 'Change' ) {
        return $Self->_Change(%Param);
    }
    elsif ( $Self->{Subaction} eq 'ChangeAction' ) {
        $LayoutObject->ChallengeTokenCheck();

        return $Self->_ChangeAction(%Param);
    }

    return $LayoutObject->ErrorScreen(
        Message => "Undefined subaction.",
    );
}

sub _Add {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');

    my %GetParam;
    NEEDED:
    for my $Needed (qw(ObjectType FieldType FieldOrder)) {
        $GetParam{$Needed} = $ParamObject->GetParam( Param => $Needed );
        next NEEDED if defined $GetParam{$Needed} && length $GetParam{$Needed};

        return $LayoutObject->ErrorScreen(
            Message => "Need $Needed.",
        );
    }

    my $ObjectTypeName = $Self->{ObjectTypeConfig}->{ $GetParam{ObjectType} }->{DisplayName} || '';
    my $FieldTypeName  = $Self->{FieldTypeConfig}->{ $GetParam{FieldType} }->{DisplayName}   || '';

    return $Self->_ShowScreen(
        %Param,
        %GetParam,
        Mode           => 'Add',
        BreadcrumbText => $LayoutObject->{LanguageObject}
            ->Translate( 'Add %s field', $LayoutObject->{LanguageObject}->Translate($FieldTypeName) ),
        ObjectTypeName => $ObjectTypeName,
        FieldTypeName  => $FieldTypeName,
    );
}

sub _AddAction {
    my ( $Self, %Param ) = @_;

    my $ConfigObject       = $Kernel::OM->Get('Kernel::Config');
    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $LayoutObject       = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject        = $Kernel::OM->Get('Kernel::System::Web::Request');

    my %Errors;
    my %GetParam;

    NEEDED:
    for my $Needed (qw(Name Label FieldOrder)) {
        $GetParam{$Needed} = $ParamObject->GetParam( Param => $Needed );
        next NEEDED if defined $GetParam{$Needed} && length $GetParam{$Needed};

        $Errors{ $Needed . 'ServerError' }        = 'ServerError';
        $Errors{ $Needed . 'ServerErrorMessage' } = 'This field is required.';
    }

    if ( $GetParam{Name} ) {

        # check if name is alphanumeric
        if ( $GetParam{Name} !~ m{\A (?: [a-zA-Z] | \d )+ \z}xms ) {
            $Errors{NameServerError} = 'ServerError';
            $Errors{NameServerErrorMessage} =
                'The field does not contain only ASCII letters and numbers.';
        }

        # check if name is duplicated
        my %DynamicFieldsList = %{
            $DynamicFieldObject->DynamicFieldList(
                Valid      => 0,
                ResultType => 'HASH',
            )
        };
        %DynamicFieldsList = reverse %DynamicFieldsList;

        if ( $DynamicFieldsList{ $GetParam{Name} } ) {
            $Errors{NameServerError}        = 'ServerError';
            $Errors{NameServerErrorMessage} = 'There is another field with the same name.';
        }
    }

    if ( $GetParam{FieldOrder} ) {

        # check if field order is numeric and positive
        if ( $GetParam{FieldOrder} !~ m{\A (?: \d )+ \z}xms ) {
            $Errors{FieldOrderServerError}        = 'ServerError';
            $Errors{FieldOrderServerErrorMessage} = 'The field must be numeric.';
        }
    }

    for my $ConfigParam (
        qw(ObjectType ObjectTypeName FieldType FieldTypeName ValidID ConfigItemClass ConfigItemLinkType ConfigItemLinkSource ConfigItemLinkRemoval)
        )
    {
        $GetParam{$ConfigParam} = $ParamObject->GetParam( Param => $ConfigParam );
    }

    my @DeplStates = $ParamObject->GetArray(
        Param => 'DeplStates',
        Raw   => 1,
    );
    if (@DeplStates) {
        $GetParam{DeplStates} = \@DeplStates;
    }

    # uncorrectable errors
    if ( !$GetParam{ValidID} ) {
        return $LayoutObject->ErrorScreen(
            Message => 'Need ValidID.',
        );
    }

    if ( !$GetParam{ConfigItemClass} ) {
        $Errors{ConfigItemClassServerError} = 'ServerError';
    }

    my @AdditionalDFStorage = $Self->_AdditionalDFStorageGet();
    $GetParam{AdditionalDFStorage} = \@AdditionalDFStorage;

    my %AdditionalDFStorageErrors = $Self->_AdditionalDFStorageValidate(%GetParam);
    %Errors = ( %Errors, %AdditionalDFStorageErrors );

    if (%Errors) {
        return $Self->_ShowScreen(
            %Param,
            %Errors,
            %GetParam,
            Mode => 'Add',
        );
    }

    my $DynamicFieldConfig;
    my $DynamicFieldDriverRegistration = $ConfigObject->Get('DynamicFields::Driver');

    if (
        IsHashRefWithData($DynamicFieldDriverRegistration)
        && IsHashRefWithData( $DynamicFieldDriverRegistration->{ $GetParam{FieldType} } )
        && IsHashRefWithData( $DynamicFieldDriverRegistration->{ $GetParam{FieldType} }->{Config} )
        )
    {
        $DynamicFieldConfig = $DynamicFieldDriverRegistration->{ $GetParam{FieldType} }->{Config};
    }

    # overwrite dynamic field config
    KEY:
    for my $Key (
        qw( ConfigItemClass DeplStates ConfigItemLinkType ConfigItemLinkSource ConfigItemLinkRemoval AdditionalDFStorage )
        )
    {
        next KEY if !defined $GetParam{$Key};
        $DynamicFieldConfig->{$Key} = $GetParam{$Key};
    }

    my $FieldID = $DynamicFieldObject->DynamicFieldAdd(
        Name       => $GetParam{Name},
        Label      => $GetParam{Label},
        FieldOrder => $GetParam{FieldOrder},
        FieldType  => $GetParam{FieldType},
        ObjectType => $GetParam{ObjectType},
        Config     => $DynamicFieldConfig || {},
        ValidID    => $GetParam{ValidID},
        UserID     => $Self->{UserID},
    );

    if ( !$FieldID ) {
        return $LayoutObject->ErrorScreen(
            Message => 'Could not create the new field.',
        );
    }

    return $LayoutObject->Redirect(
        OP => "Action=AdminDynamicField",
    );
}

sub _Change {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $LayoutObject       = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject        = $Kernel::OM->Get('Kernel::System::Web::Request');

    my $FieldID = $ParamObject->GetParam( Param => 'ID' );
    if ( !$FieldID ) {
        return $LayoutObject->ErrorScreen(
            Message => 'Need ID.',
        );
    }

    my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
        ID => $FieldID,
    );
    if ( !IsHashRefWithData($DynamicFieldConfig) ) {
        return $LayoutObject->ErrorScreen(
            Message => "Could not get config for dynamic field $FieldID.",
        );
    }

    my %Config;
    if ( IsHashRefWithData( $DynamicFieldConfig->{Config} ) ) {
        %Config = %{ $DynamicFieldConfig->{Config} };
    }

    # Initialize GetParam with read-only values that cannot be changed anymore in change dialog.
    my %GetParam = (
        ObjectType      => $DynamicFieldConfig->{ObjectType},
        FieldType       => $DynamicFieldConfig->{FieldType},
        ConfigItemClass => $Config{ConfigItemClass},
    );

    my $ObjectTypeName = $Self->{ObjectTypeConfig}->{ $GetParam{ObjectType} }->{DisplayName} || '';
    my $FieldTypeName  = $Self->{FieldTypeConfig}->{ $GetParam{FieldType} }->{DisplayName}   || '';

    return $Self->_ShowScreen(
        %Param,
        %GetParam,
        %{$DynamicFieldConfig},
        %Config,
        ID             => $FieldID,
        Mode           => 'Change',
        BreadcrumbText => $LayoutObject->{LanguageObject}
            ->Translate( 'Change %s field', $LayoutObject->{LanguageObject}->Translate($FieldTypeName) ),
        ObjectTypeName => $ObjectTypeName,
        FieldTypeName  => $FieldTypeName,
    );
}

sub _ChangeAction {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $LayoutObject       = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject        = $Kernel::OM->Get('Kernel::System::Web::Request');

    my %Errors;
    my %GetParam;

    NEEDED:
    for my $Needed (qw(Name Label FieldOrder)) {
        $GetParam{$Needed} = $ParamObject->GetParam( Param => $Needed );
        next NEEDED if defined $GetParam{$Needed} && length $GetParam{$Needed};

        $Errors{ $Needed . 'ServerError' }        = 'ServerError';
        $Errors{ $Needed . 'ServerErrorMessage' } = 'This field is required.';
    }

    my $FieldID = $ParamObject->GetParam( Param => 'ID' );
    if ( !$FieldID ) {
        return $LayoutObject->ErrorScreen(
            Message => 'Need ID.',
        );
    }
    my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
        ID => $FieldID,
    );
    if ( !IsHashRefWithData($DynamicFieldConfig) ) {
        return $LayoutObject->ErrorScreen(
            Message => "Could not get config for dynamic field $FieldID.",
        );
    }

    if ( $GetParam{Name} ) {

        # check if name is lowercase
        if ( $GetParam{Name} !~ m{\A (?: [a-zA-Z] | \d )+ \z}xms ) {
            $Errors{NameServerError} = 'ServerError';
            $Errors{NameServerErrorMessage} =
                'The field does not contain only ASCII letters and numbers.';
        }

        # check if name is duplicated
        my %DynamicFieldsList = %{
            $DynamicFieldObject->DynamicFieldList(
                Valid      => 0,
                ResultType => 'HASH',
            )
        };
        %DynamicFieldsList = reverse %DynamicFieldsList;

        if (
            $DynamicFieldsList{ $GetParam{Name} } &&
            $DynamicFieldsList{ $GetParam{Name} } ne $FieldID
            )
        {
            $Errors{NameServerError}        = 'ServerError';
            $Errors{NameServerErrorMessage} = 'There is another field with the same name.';
        }

        # if it's an internal field, its name should not change
        if (
            $DynamicFieldConfig->{InternalField} &&
            $DynamicFieldsList{ $GetParam{Name} } ne $FieldID
            )
        {
            $Errors{NameServerError}        = 'ServerError';
            $Errors{NameServerErrorMessage} = 'The name for this field should not change.';
            $Param{InternalField}           = $DynamicFieldConfig->{InternalField};
        }
    }

    if ( $GetParam{FieldOrder} ) {

        # check if field order is numeric and positive
        if ( $GetParam{FieldOrder} !~ m{\A (?: \d )+ \z}xms ) {
            $Errors{FieldOrderServerError}        = 'ServerError';
            $Errors{FieldOrderServerErrorMessage} = 'The field must be numeric.';
        }
    }

    for my $ConfigParam (
        qw(ObjectType ObjectTypeName FieldType FieldTypeName DefaultValue ValidID ConfigItemLinkType ConfigItemLinkSource ConfigItemLinkRemoval)
        )
    {
        $GetParam{$ConfigParam} = $ParamObject->GetParam( Param => $ConfigParam );
    }

    # Config item class is read-only in change, so set it to the stored value every time.
    $GetParam{ConfigItemClass} = $DynamicFieldConfig->{Config}->{ConfigItemClass};

    my @DeplStates = $ParamObject->GetArray(
        Param => 'DeplStates',
        Raw   => 1,
    );
    $GetParam{DeplStates} = \@DeplStates;
    $DynamicFieldConfig->{Config}->{DeplStates} = \@DeplStates;

    $DynamicFieldConfig->{Config}->{ConfigItemLinkType}    = $GetParam{ConfigItemLinkType};
    $DynamicFieldConfig->{Config}->{ConfigItemLinkSource}  = $GetParam{ConfigItemLinkSource};
    $DynamicFieldConfig->{Config}->{ConfigItemLinkRemoval} = $GetParam{ConfigItemLinkRemoval};

    if ( !$GetParam{ValidID} ) {
        return $LayoutObject->ErrorScreen(
            Message => 'Need ValidID.',
        );
    }

    my @AdditionalDFStorage = $Self->_AdditionalDFStorageGet();
    $GetParam{AdditionalDFStorage} = \@AdditionalDFStorage;

    my %AdditionalDFStorageErrors = $Self->_AdditionalDFStorageValidate(%GetParam);
    %Errors = ( %Errors, %AdditionalDFStorageErrors );

    # return to change screen if errors
    if (%Errors) {
        return $Self->_ShowScreen(
            %Param,
            %Errors,
            %GetParam,
            ID   => $FieldID,
            Mode => 'Change',
        );
    }

    $DynamicFieldConfig->{Config}->{AdditionalDFStorage} = $GetParam{AdditionalDFStorage};

    # update dynamic field (FieldType and ObjectType cannot be changed - use old values)
    my $UpdateSuccess = $DynamicFieldObject->DynamicFieldUpdate(
        ID         => $FieldID,
        Name       => $GetParam{Name},
        Label      => $GetParam{Label},
        FieldOrder => $GetParam{FieldOrder},
        FieldType  => $DynamicFieldConfig->{FieldType},
        ObjectType => $DynamicFieldConfig->{ObjectType},
        Config     => $DynamicFieldConfig->{Config} || {},
        ValidID    => $GetParam{ValidID},
        UserID     => $Self->{UserID},
    );

    if ( !$UpdateSuccess ) {
        return $LayoutObject->ErrorScreen(
            Message => "Could not update the field $GetParam{Name}.",
        );
    }

    if ( $ParamObject->GetParam( Param => 'ContinueAfterSave' ) ) {
        return $LayoutObject->Redirect(
            OP =>
                "Action=$Self->{Action};Subaction=Change;ObjectType=$GetParam{ObjectType};FieldType=$GetParam{FieldType};ID=$FieldID"
        );
    }

    return $LayoutObject->Redirect(
        OP => "Action=AdminDynamicField",
    );
}

sub _ShowScreen {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldObject   = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my $LayoutObject         = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ValidObject          = $Kernel::OM->Get('Kernel::System::Valid');
    my $LinkObject           = $Kernel::OM->Get('Kernel::System::LinkObject');
    my $LanguageObject       = $Kernel::OM->Get('Kernel::Language');

    $Param{DisplayFieldName} = 'New';

    if ( $Param{Mode} eq 'Change' ) {
        $Param{ShowWarning}      = 'ShowWarning';
        $Param{DisplayFieldName} = $Param{Name};
    }

    my $Output = $LayoutObject->Header();
    $Output .= $LayoutObject->NavigationBar();

    my $DynamicFieldList = $DynamicFieldObject->DynamicFieldListGet(
        Valid => 0,
    );

    # get the list of order numbers (is already sorted).
    my @DynamicfieldOrderList;
    my %DynamicfieldNamesList;
    for my $Dynamicfield ( @{$DynamicFieldList} ) {
        push @DynamicfieldOrderList, $Dynamicfield->{FieldOrder};
        $DynamicfieldNamesList{ $Dynamicfield->{FieldOrder} } = $Dynamicfield->{Label};
    }

    # when adding we need to create an extra order number for the new field
    if ( $Param{Mode} eq 'Add' ) {

        # get the last element form the order list and add 1
        my $LastOrderNumber = $DynamicfieldOrderList[-1];
        $LastOrderNumber++;

        # add this new order number to the end of the list
        push @DynamicfieldOrderList, $LastOrderNumber;
    }

    # show the names of the other fields to ease ordering
    my %OrderNamesList;
    my $CurrentlyText = $LayoutObject->{LanguageObject}->Translate('Currently') . ': ';
    for my $OrderNumber ( sort @DynamicfieldOrderList ) {
        $OrderNamesList{$OrderNumber} = $OrderNumber;
        if ( $DynamicfieldNamesList{$OrderNumber} && $OrderNumber ne $Param{FieldOrder} ) {
            $OrderNamesList{$OrderNumber} = $OrderNumber . ' - '
                . $CurrentlyText
                . $DynamicfieldNamesList{$OrderNumber};
        }
    }

    my $DynamicFieldOrderStrg = $LayoutObject->BuildSelection(
        Data          => \%OrderNamesList,
        Name          => 'FieldOrder',
        SelectedValue => $Param{FieldOrder} || 1,
        PossibleNone  => 0,
        Translation   => 0,
        Sort          => 'NumericKey',
        Class         => 'W75pc Validate_Number',
    );

    my %ValidList    = $ValidObject->ValidList();
    my $ValidityStrg = $LayoutObject->BuildSelection(
        Data         => \%ValidList,
        Name         => 'ValidID',
        SelectedID   => $Param{ValidID} || 1,
        PossibleNone => 0,
        Translation  => 1,
        Class        => 'W50pc',
    );

    my %ShowParams = $Self->_AdditionalDFStorageShow(
        %Param
    );
    %Param = ( %Param, %ShowParams );

    my $ReadonlyInternalField = '';

    # Internal fields can not be deleted and name should not change.
    if ( $Param{InternalField} ) {
        $LayoutObject->Block(
            Name => 'InternalField',
            Data => {%Param},
        );
        $ReadonlyInternalField = 'readonly="readonly"';
    }

    my $ClassList = $GeneralCatalogObject->ItemList(
        Class => 'ITSM::ConfigItem::Class',
    );

    my $ConfigItemClasses = [ sort values %{ $ClassList || {} } ];
    my %ConfigItemClasses = map { $_ => $_ } @{$ConfigItemClasses};

    # Add 'invalid' note to config class name if the class is invalid
    # or does not exist (anymore).
    my $SelectedConfigItemClassIsInvalid;
    if (
        $Param{Mode} eq 'Change'
        && $Param{ConfigItemClass}
        && !$ConfigItemClasses{ $Param{ConfigItemClass} }
        )
    {
        $SelectedConfigItemClassIsInvalid = 1;
        $ConfigItemClasses{ $Param{ConfigItemClass} } = $LanguageObject->Translate( $Param{ConfigItemClass} )
            . ' ('
            . $LanguageObject->Translate('invalid')
            . ')';
    }

    # disable field in change dialogs
    my $Disabled = $Param{Mode} eq 'Change' ? 1 : 0;

    $Param{ConfigItemClassStrg} = $LayoutObject->BuildSelection(
        Data         => \%ConfigItemClasses,
        SelectedID   => $Param{ConfigItemClass},
        Class        => 'Modernize Validate_Required  ' . ( $Param{ConfigItemClassServerError} || ' ' ),
        Translation  => 1,
        Name         => 'ConfigItemClass',
        PossibleNone => 1,
        Disabled     => $Disabled,
        Sort         => 'AlphanumericKey',
    );

    # selection of deployment status
    my $DeplStateList = $GeneralCatalogObject->ItemList(
        Class => 'ITSM::ConfigItem::DeploymentState',
    );

    my $DeplStates = [ sort values %{ $DeplStateList || {} } ];
    my %DeplStates = map { $_ => $_ } @{$DeplStates};

    my $DeplStateSelectionHTML = $LayoutObject->BuildSelection(
        Data         => \%DeplStates,
        Name         => 'DeplStates',
        PossibleNone => 0,
        Translation  => 1,
        Class        => 'Modernize',
        Multiple     => 1,
        SelectedID   => $Param{DeplStates},
    );

    # selection of link type
    my %PossibleConfigItemLinkTypes = $LinkObject->PossibleTypesList(
        Object1 => $Param{ObjectType},
        Object2 => 'ITSMConfigItem',
    );

    my @PossibleConfigItemLinkTypes = keys %PossibleConfigItemLinkTypes;

    my $ConfigItemLinkTypeSelectionHTML = $LayoutObject->BuildSelection(
        Data          => \@PossibleConfigItemLinkTypes,
        Name          => 'ConfigItemLinkType',
        PossibleNone  => 1,
        Class         => 'Modernize',
        Multiple      => 0,
        SelectedValue => $Param{ConfigItemLinkType},
    );

    # selection of config item link source
    my %ConfigItemLinkSources = (
        ITSMConfigItem     => 'Config item',
        $Param{ObjectType} => $Param{ObjectType},
    );

    my $ConfigItemLinkSourceSelectionHTML = $LayoutObject->BuildSelection(
        Data         => \%ConfigItemLinkSources,
        Name         => 'ConfigItemLinkSource',
        PossibleNone => 0,
        Class        => 'Modernize',
        Multiple     => 0,
        SelectedID   => $Param{ConfigItemLinkSource},
    );

    # selection for config item link removal
    my $ConfigItemLinkRemovalSelectionHTML = $LayoutObject->BuildSelection(
        Data => {
            0 => Translatable('No'),
            1 => Translatable('Yes'),
        },
        Name       => 'ConfigItemLinkRemoval',
        SelectedID => $Param{ConfigItemLinkRemoval} // 1,
        Class      => 'Modernize',
    );

    $Output .= $LayoutObject->Output(
        TemplateFile => 'AdminDynamicFieldConfigItem',
        Data         => {
            %Param,
            SelectedConfigItemClassIsInvalid   => $SelectedConfigItemClassIsInvalid,
            DeplStateSelectionHTML             => $DeplStateSelectionHTML,
            ConfigItemLinkTypeSelectionHTML    => $ConfigItemLinkTypeSelectionHTML,
            ConfigItemLinkSourceSelectionHTML  => $ConfigItemLinkSourceSelectionHTML,
            ConfigItemLinkRemovalSelectionHTML => $ConfigItemLinkRemovalSelectionHTML,
            ValidityStrg                       => $ValidityStrg,
            DynamicFieldOrderStrg              => $DynamicFieldOrderStrg,
            ReadonlyInternalField              => $ReadonlyInternalField,
        },
    );

    $Output .= $LayoutObject->Footer();

    return $Output;
}

sub _AdditionalDFStorageShow {
    my ( $Self, %Param ) = @_;

    my $LayoutObject       = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');

    my %ShowParams;

    # Only ticket dynamic fields are supported for additional dynamic field storage.
    return %ShowParams if !$Param{ObjectType};
    return %ShowParams if $Param{ObjectType} ne 'Ticket';

    my @AdditionalDFStorage;
    if ( IsArrayRefWithData( $Param{AdditionalDFStorage} ) ) {
        @AdditionalDFStorage = @{ $Param{AdditionalDFStorage} };
    }

    $LayoutObject->Block(
        Name => 'AdditionalDFStorage',
        Data => {},
    );

    # Assemble available dynamic fields to be additionally filled.
    my $AdditionalDynamicFieldConfigs = $DynamicFieldObject->DynamicFieldListGet(
        ObjectType => 'Ticket',
    );

    # Filter out dynamic field that is currently being configured. It's not available
    # to be selected as an additional dynamic field to be filled.
    my @AdditionalDynamicFieldConfigs = @{$AdditionalDynamicFieldConfigs};
    if ( defined $Param{Name} ) {
        @AdditionalDynamicFieldConfigs = grep { $_->{Name} ne $Param{Name} } @{$AdditionalDynamicFieldConfigs};
    }

    my %AdditionalDynamicFieldSelection
        = map { $_->{Name} => $_->{Name} . '(' . $_->{Label} . ')' } @AdditionalDynamicFieldConfigs;

    my $AdditionalDFStorageValueCounter = 0;
    for my $Storage (@AdditionalDFStorage) {
        my $DynamicField  = $Storage->{DynamicField};
        my $ConfigItemKey = $Storage->{ConfigItemKey};
        my $Type          = $Storage->{Type};

        my $DynamicFieldError        = '';
        my $DynamicFieldErrorMessage = Translatable('This field is required');    # default in template

        my $ConfigItemKeyError        = '';
        my $ConfigItemKeyErrorMessage = Translatable('This field is required');    # default in template;

        if ( $Param{AdditionalDFStorageErrors} ) {

            # Dynamic field error
            if ( defined $Param{AdditionalDFStorageErrors}->[$AdditionalDFStorageValueCounter]->{DynamicField} ) {
                $DynamicFieldError = 'ServerError';
                $DynamicFieldErrorMessage
                    = $Param{AdditionalDFStorageErrors}->[$AdditionalDFStorageValueCounter]->{DynamicField};
            }

            # Config item key error
            if ( defined $Param{AdditionalDFStorageErrors}->[$AdditionalDFStorageValueCounter]->{ConfigItemKey} ) {
                $ConfigItemKeyError = 'ServerError';
                $ConfigItemKeyErrorMessage
                    = $Param{AdditionalDFStorageErrors}->[$AdditionalDFStorageValueCounter]->{ConfigItemKey};
            }
        }

        $AdditionalDFStorageValueCounter++;

        my $DynamicFieldSelection = $LayoutObject->BuildSelection(
            Data         => \%AdditionalDynamicFieldSelection,
            Sort         => 'AlphanumericValue',
            Name         => 'DynamicField_' . $AdditionalDFStorageValueCounter,
            SelectedID   => $DynamicField,
            PossibleNone => 1,
            Translation  => 0,
            Class        => "Modernize VariableWidth DataTable Validate_Required $DynamicFieldError",
        );

        my $TypeOption = $LayoutObject->BuildSelection(
            Data => {
                Frontend        => 'Frontend',
                Backend         => 'Backend',
                FrontendBackend => 'Frontend and Backend',
            },
            Sort           => 'IndividualKey',
            SortIndividual => [ 'Backend', 'Frontend', 'FrontendBackend' ],
            Name           => 'Type_' . $AdditionalDFStorageValueCounter,
            SelectedID     => $Type || 'Backend',
            PossibleNone   => 0,
            Translation    => 1,
            Class          => 'Modernize',
        );

        # create a value map row
        $LayoutObject->Block(
            Name => 'AdditionalDFStorageRow',
            Data => {
                AdditionalDFStorageValueCounter => $AdditionalDFStorageValueCounter,
                DynamicFieldSelection           => $DynamicFieldSelection,
                DynamicFieldErrorMessage        => $DynamicFieldErrorMessage,
                ConfigItemKey                   => $ConfigItemKey,
                ConfigItemKeyError              => $ConfigItemKeyError,
                ConfigItemKeyErrorMessage       => $ConfigItemKeyErrorMessage,
                TypeOption                      => $TypeOption,
            },
        );
    }

    $Param{TypeOption} = $LayoutObject->BuildSelection(
        Data => {
            Frontend        => 'Frontend',
            Backend         => 'Backend',
            FrontendBackend => 'Frontend and Backend',
        },
        Sort           => 'IndividualKey',
        SortIndividual => [ 'Backend', 'Frontend', 'FrontendBackend' ],
        Name           => 'Type',
        SelectedID     => $Param{Type} // 'Backend',
        PossibleNone   => 0,
        Translation    => 1,
        Class          => 'Modernize',
    );

    # create AdditionalDFStorage template
    $Param{DynamicFieldSelectionTemplate} = $LayoutObject->BuildSelection(
        Data         => \%AdditionalDynamicFieldSelection,
        Sort         => 'AlphanumericValue',
        Name         => 'DynamicField',
        PossibleNone => 1,
        Translation  => 0,
        Class        => 'Modernize VariableWidth DataTable',
    );

    $LayoutObject->Block(
        Name => 'AdditionalDFStorageTemplate',
        Data => {
            %Param,
        },
    );

    $LayoutObject->Block(
        Name => 'AdditionalDFStorageValueCounter',
        Data => {
            AdditionalDFStorageValueCounter => $AdditionalDFStorageValueCounter,
        },
    );

    $ShowParams{AdditionalDFStorageValueCounter} = $AdditionalDFStorageValueCounter;

    return %ShowParams;
}

sub _AdditionalDFStorageGet {
    my ( $Self, %Param ) = @_;

    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    my @AdditionalDFStorage;

    my $ValueCounter = $ParamObject->GetParam( Param => 'AdditionalDFStorageValueCounter' ) // 0;

    VALUECOUNTERINDEX:
    for my $ValueCounterIndex ( 1 .. $ValueCounter ) {
        my $DynamicField = $ParamObject->GetParam( Param => 'DynamicField_' . $ValueCounterIndex );
        next VALUECOUNTERINDEX if !defined $DynamicField;

        my $ConfigItemKey = $ParamObject->GetParam( Param => 'ConfigItemKey_' . $ValueCounterIndex );
        my $Type          = $ParamObject->GetParam( Param => 'Type_' . $ValueCounterIndex ) // 'Backend';

        push @AdditionalDFStorage, {
            DynamicField  => $DynamicField,
            ConfigItemKey => $ConfigItemKey,
            Type          => $Type,
        };
    }

    return @AdditionalDFStorage;
}

sub _AdditionalDFStorageValidate {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');

    my @AdditionalDFStorage = @{ $Param{AdditionalDFStorage} // [] };

    my %UsedDynamicFields;
    my @StorageErrorMessages;
    my $StorageErrorFound;

    STORAGE:
    for my $Storage (@AdditionalDFStorage) {
        my $DynamicField  = $Storage->{DynamicField};
        my $ConfigItemKey = $Storage->{ConfigItemKey};
        my $Type          = $Storage->{Type};

        my %StorageErrorMessages;

        # Check dynamic field.
        if ( !defined $DynamicField || !length $DynamicField ) {
            $StorageErrorMessages{DynamicField} = Translatable('This field is required.');
        }
        elsif ( $UsedDynamicFields{$DynamicField} ) {
            $StorageErrorMessages{DynamicField} = Translatable('Dynamic field is configured more than once.');
        }
        else {
            my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
                Name => $DynamicField,
            );
            if ( !IsHashRefWithData($DynamicFieldConfig) ) {
                $StorageErrorMessages{DynamicField} = Translatable('Dynamic field does not exist or is invalid.');
            }
            elsif ( $DynamicFieldConfig->{ObjectType} ne 'Ticket' ) {
                $StorageErrorMessages{DynamicField} = Translatable('Only dynamic fields for tickets are allowed.');
            }
        }

        if ( defined $DynamicField && length $DynamicField ) {
            $UsedDynamicFields{$DynamicField} = 1;
        }

        # Check config item key.
        if ( !defined $ConfigItemKey || !length $ConfigItemKey ) {
            $StorageErrorMessages{ConfigItemKey} = Translatable('This field is required.');
        }

        # Important: push even if %StorageErrorMessages is empty
        # because the index in @StorageErrorMessages must match the one of @AdditionalDFStorage.
        push @StorageErrorMessages, \%StorageErrorMessages;

        $StorageErrorFound = 1 if %StorageErrorMessages;
    }

    my %Errors;
    if ($StorageErrorFound) {
        $Errors{AdditionalDFStorageErrors} = \@StorageErrorMessages;
    }

    return %Errors;
}

1;
