# --
# Copyright (C) 2012-2019 Znuny GmbH, http://znuny.com/
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

    # get configured object types
    $Self->{ObjectTypeConfig} = $ConfigObject->Get('DynamicFields::ObjectType');

    # get the fields config
    $Self->{FieldTypeConfig} = $ConfigObject->Get('DynamicFields::Driver') || {};

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    $LayoutObject->AddJSOnDocumentCompleteIfNotExists(
        Key  => 'AdminDynamicFieldConfigItem',
        Code => 'Core.Agent.Admin.Znuny4OTRSDynamicFieldConfigItem.Init();',
    );

    if ( $Self->{Subaction} eq 'Add' ) {
        return $Self->_Add(
            %Param,
        );
    }
    elsif ( $Self->{Subaction} eq 'AddAction' ) {
        $LayoutObject->ChallengeTokenCheck();

        return $Self->_AddAction(
            %Param,
        );
    }
    if ( $Self->{Subaction} eq 'Change' ) {
        return $Self->_Change(
            %Param,
        );
    }
    elsif ( $Self->{Subaction} eq 'ChangeAction' ) {
        $LayoutObject->ChallengeTokenCheck();

        return $Self->_ChangeAction(
            %Param,
        );
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

        next NEEDED if $Needed;

        return $LayoutObject->ErrorScreen(
            Message => "Need $Needed.",
        );
    }

    # get the object type and field type display name
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

        next NEEDED if $GetParam{$Needed};

        $Errors{ $Needed . 'ServerError' }        = 'ServerError';
        $Errors{ $Needed . 'ServerErrorMessage' } = 'This field is required.';
    }

    if ( $GetParam{Name} ) {

        # check if name is alphanumeric
        if ( $GetParam{Name} !~ m{\A (?: [a-zA-Z] | \d )+ \z}xms ) {

            # add server error error class
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

            # add server error error class
            $Errors{NameServerError}        = 'ServerError';
            $Errors{NameServerErrorMessage} = 'There is another field with the same name.';
        }
    }

    if ( $GetParam{FieldOrder} ) {

        # check if field order is numeric and positive
        if ( $GetParam{FieldOrder} !~ m{\A (?: \d )+ \z}xms ) {

            # add server error error class
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

    my @DeplStateIDs = $ParamObject->GetArray(
        Param => 'DeplStateIDs',
        Raw   => 1,
    );
    if (@DeplStateIDs) {
        $GetParam{DeplStateIDs} = \@DeplStateIDs;
    }

    # uncorrectable errors
    if ( !$GetParam{ValidID} ) {
        return $LayoutObject->ErrorScreen(
            Message => 'Need ValidID.',
        );
    }

    # check config item class
    if ( !$GetParam{ConfigItemClass} ) {
        $Errors{ConfigItemClassServerError} = 'ServerError';
    }

    # return to add screen if errors
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

    # overwrite dynamic field configs
    KEY:
    for my $Key (qw( ConfigItemClass DeplStateIDs ConfigItemLinkType ConfigItemLinkSource ConfigItemLinkRemoval )) {
        next KEY if !$GetParam{$Key};

        $DynamicFieldConfig->{$Key} = $GetParam{$Key};
    }

    # create a new field
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

    my %GetParam;
    for my $Needed (qw(ObjectType FieldType ConfigItemClass)) {
        $GetParam{$Needed} = $ParamObject->GetParam( Param => $Needed );
        if ( !$Needed ) {
            return $LayoutObject->ErrorScreen(
                Message => "Need $Needed.",
            );
        }
    }

    # get the object type and field type display name
    my $ObjectTypeName = $Self->{ObjectTypeConfig}->{ $GetParam{ObjectType} }->{DisplayName} || '';
    my $FieldTypeName  = $Self->{FieldTypeConfig}->{ $GetParam{FieldType} }->{DisplayName}   || '';

    my $FieldID = $ParamObject->GetParam( Param => 'ID' );
    if ( !$FieldID ) {
        return $LayoutObject->ErrorScreen(
            Message => 'Need ID.',
        );
    }

    my $DynamicFieldData = $DynamicFieldObject->DynamicFieldGet(
        ID => $FieldID,
    );
    if ( !IsHashRefWithData($DynamicFieldData) ) {
        return $LayoutObject->ErrorScreen(
            Message => "Could not get data for dynamic field $FieldID.",
        );
    }

    my %Config;

    # extract configuration
    if ( IsHashRefWithData( $DynamicFieldData->{Config} ) ) {
        %Config = %{ $DynamicFieldData->{Config} };
    }

    # overwrite config item class
    if ( $GetParam{ConfigItemClass} ) {
        $Config{ConfigItemClass} = $GetParam{ConfigItemClass};
    }

    return $Self->_ShowScreen(
        %Param,
        %GetParam,
        %{$DynamicFieldData},
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

        next NEEDED if $GetParam{$Needed};

        $Errors{ $Needed . 'ServerError' }        = 'ServerError';
        $Errors{ $Needed . 'ServerErrorMessage' } = 'This field is required.';
    }

    my $FieldID = $ParamObject->GetParam( Param => 'ID' );
    if ( !$FieldID ) {
        return $LayoutObject->ErrorScreen(
            Message => 'Need ID.',
        );
    }
    my $DynamicFieldData = $DynamicFieldObject->DynamicFieldGet(
        ID => $FieldID,
    );
    if ( !IsHashRefWithData($DynamicFieldData) ) {
        return $LayoutObject->ErrorScreen(
            Message => "Could not get data for dynamic field $FieldID.",
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
            $DynamicFieldData->{InternalField} &&
            $DynamicFieldsList{ $GetParam{Name} } ne $FieldID
            )
        {

            # add server error class
            $Errors{NameServerError}        = 'ServerError';
            $Errors{NameServerErrorMessage} = 'The name for this field should not change.';
            $Param{InternalField}           = $DynamicFieldData->{InternalField};
        }
    }

    if ( $GetParam{FieldOrder} ) {

        # check if field order is numeric and positive
        if ( $GetParam{FieldOrder} !~ m{\A (?: \d )+ \z}xms ) {

            # add server error error class
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

    # Config item class is read-only in change, so set it to the stored value everytime.
    $GetParam{ConfigItemClass} = $DynamicFieldData->{Config}->{ConfigItemClass};

    my @DeplStateIDs = $ParamObject->GetArray(
        Param => 'DeplStateIDs',
        Raw   => 1,
    );
    $GetParam{DeplStateIDs} = \@DeplStateIDs;
    $DynamicFieldData->{Config}->{DeplStateIDs} = \@DeplStateIDs;

    $DynamicFieldData->{Config}->{ConfigItemLinkType}    = $GetParam{ConfigItemLinkType};
    $DynamicFieldData->{Config}->{ConfigItemLinkSource}  = $GetParam{ConfigItemLinkSource};
    $DynamicFieldData->{Config}->{ConfigItemLinkRemoval} = $GetParam{ConfigItemLinkRemoval};

    if ( !$GetParam{ValidID} ) {
        return $LayoutObject->ErrorScreen(
            Message => 'Need ValidID.',
        );
    }

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

    # update dynamic field (FieldType and ObjectType cannot be changed; use old values)
    my $UpdateSuccess = $DynamicFieldObject->DynamicFieldUpdate(
        ID         => $FieldID,
        Name       => $GetParam{Name},
        Label      => $GetParam{Label},
        FieldOrder => $GetParam{FieldOrder},
        FieldType  => $DynamicFieldData->{FieldType},
        ObjectType => $DynamicFieldData->{ObjectType},
        Config     => $DynamicFieldData->{Config} || {},
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

    my $ReadonlyInternalField = '';

    # Internal fields can not be deleted and name should not change.
    if ( $Param{InternalField} ) {
        $LayoutObject->Block(
            Name => 'InternalField',
            Data => {%Param},
        );
        $ReadonlyInternalField = 'readonly="readonly"';
    }

    # get values for classes
    my $ItemListRef = $GeneralCatalogObject->ItemList(
        Class => 'ITSM::ConfigItem::Class',
    );

    my $ClassList = [ sort values %{ $ItemListRef || {} } ];

    # disable field in change dialogs
    my $Disabled = $Param{Mode} eq 'Change' ? 1 : 0;

    $Param{ConfigItemClassStrg} = $LayoutObject->BuildSelection(
        Data         => $ClassList,
        SelectedID   => $Param{ConfigItemClass},
        Class        => 'Modernize Validate_Required  ' . ( $Param{ConfigItemClassServerError} || ' ' ),
        Translation  => 1,
        Name         => 'ConfigItemClass',
        PossibleNone => 1,
        Disabled     => $Disabled,
        Sort         => 'AlphanumericKey',
    );

    # selection of deployment status
    my $DeplStates = $GeneralCatalogObject->ItemList(
        Class => 'ITSM::ConfigItem::DeploymentState',
    );

    my $DeplStateSelectionHTML = $LayoutObject->BuildSelection(
        Data         => $DeplStates,
        Name         => 'DeplStateIDs',
        PossibleNone => 0,
        Class        => 'Modernize',
        Multiple     => 1,
        SelectedID   => $Param{DeplStateIDs},
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
            DeplStateSelectionHTML             => $DeplStateSelectionHTML,
            ConfigItemLinkTypeSelectionHTML    => $ConfigItemLinkTypeSelectionHTML,
            ConfigItemLinkSourceSelectionHTML  => $ConfigItemLinkSourceSelectionHTML,
            ConfigItemLinkRemovalSelectionHTML => $ConfigItemLinkRemovalSelectionHTML,
            ValidityStrg                       => $ValidityStrg,
            DynamicFieldOrderStrg              => $DynamicFieldOrderStrg,
            ReadonlyInternalField              => $ReadonlyInternalField,
            }
    );

    $Output .= $LayoutObject->Footer();

    return $Output;
}

1;
