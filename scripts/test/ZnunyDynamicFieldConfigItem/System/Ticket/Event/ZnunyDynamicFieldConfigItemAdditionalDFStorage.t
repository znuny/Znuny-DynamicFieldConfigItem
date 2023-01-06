# --
# Copyright (C) 2012 Znuny GmbH, https://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::System::ObjectManager;

use Kernel::System::VariableCheck qw(:all);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $HelperObject                      = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ConfigItemObject                  = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
my $GeneralCatalogObject              = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
my $DynamicFieldObject                = $Kernel::OM->Get('Kernel::System::DynamicField');
my $DynamicFieldBackendObject         = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
my $ValidObject                       = $Kernel::OM->Get('Kernel::System::Valid');
my $TicketObject                      = $Kernel::OM->Get('Kernel::System::Ticket');
my $ZnunyHelperObject                 = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $ZnunyDynamicFieldConfigItemObject = $Kernel::OM->Get('Kernel::System::ZnunyDynamicFieldConfigItem');

my $ValidID = $ValidObject->ValidLookup(
    Valid => 'valid',
);

my $UserID = 1;

#
# Prepare config item
#
my $ClassListRef = $GeneralCatalogObject->ItemList(
    Class => 'ITSM::ConfigItem::Class',
    Valid => $ValidID,
);
my %ClassList = reverse %{ $ClassListRef || {} };

my $YesNoRef = $GeneralCatalogObject->ItemList(
    Class => 'ITSM::ConfigItem::YesNo',
    Valid => $ValidID,
);
my %YesNoList = reverse %{ $YesNoRef || {} };

my $ConfigItem1ID = $ConfigItemObject->ConfigItemAdd(
    ClassID => $ClassList{Computer},
    UserID  => $UserID,
);

$Self->True(
    scalar $ConfigItem1ID,
    'Config item must have been created successfully.',
);

my $ConfigItem1VersionID = $ZnunyHelperObject->_ITSMConfigItemVersionAdd(
    ConfigItemID  => $ConfigItem1ID,
    Name          => 'Unit test computer 1',
    ClassName     => 'Computer',
    DeplStateName => 'Production',
    InciStateName => 'Operational',
    XMLData       => {
        OtherEquipment         => 'Mouse',
        Note                   => 'Unit test computer 1 note.',
        WarrantyExpirationDate => '2040-01-01',
        InstallDate            => '2040-01-01',
        CPU                    => [
            {
                Content => 'CPU 1',
            },
            {
                Content => 'CPU 2',
            },
        ],
        NIC => [
            {
                Content    => 'NIC',
                IPoverDHCP => [
                    {
                        Content => $YesNoList{Yes},
                    },
                ],
                IPAddress => [
                    {
                        Content => '127.0.0.1'
                    },
                ],
            },
        ],
    },
);

$Self->True(
    scalar $ConfigItem1VersionID,
    'Config item version must have been created successfully.',
);

my $ConfigItem2ID = $ConfigItemObject->ConfigItemAdd(
    ClassID => $ClassList{Computer},
    UserID  => $UserID,
);

$Self->True(
    scalar $ConfigItem2ID,
    'Config item must have been created successfully.',
);

my $ConfigItem2VersionID = $ZnunyHelperObject->_ITSMConfigItemVersionAdd(
    ConfigItemID  => $ConfigItem2ID,
    Name          => 'Unit test computer 2',
    ClassName     => 'Computer',
    DeplStateName => 'Production',
    InciStateName => 'Operational',
    XMLData       => {
        OtherEquipment         => 'Mouse',
        Note                   => 'Unit test computer 2 note.',
        WarrantyExpirationDate => '2041-01-01',
        InstallDate            => '2041-01-01',
        CPU                    => [
            {
                Content => 'CPU 1',
            },
            {
                Content => 'CPU 4',
            },
        ],
        NIC => [
            {
                Content    => 'NIC',
                IPoverDHCP => [
                    {
                        Content => $YesNoList{No},
                    },
                ],
                IPAddress => [
                    {
                        Content => '127.0.0.2'
                    },
                ],
            },
        ],
    },
);

$Self->True(
    scalar $ConfigItem2VersionID,
    'Config item version must have been created successfully.',
);

#
# Prepare dynamic fields.
#
my @DynamicFields = (
    {
        Name          => 'ZnunyDynamicFieldConfigItemUnitTestText1',
        Label         => 'ZnunyDynamicFieldConfigItemUnitTestText1',
        InternalField => 0,
        ObjectType    => 'Ticket',
        FieldType     => 'Text',
        Config        => {
            DefaultValue => '',
        },
    },
    {
        Name          => 'ZnunyDynamicFieldConfigItemUnitTestText2',
        Label         => 'ZnunyDynamicFieldConfigItemUnitTestText2',
        InternalField => 0,
        ObjectType    => 'Ticket',
        FieldType     => 'Text',
        Config        => {
            DefaultValue => '',
        },
    },
    {
        Name          => 'ZnunyDynamicFieldConfigItemUnitTestText3',
        Label         => 'ZnunyDynamicFieldConfigItemUnitTestText3',
        InternalField => 0,
        ObjectType    => 'Ticket',
        FieldType     => 'Text',
        Config        => {
            DefaultValue => '',
        },
    },
    {
        Name          => 'ZnunyDynamicFieldConfigItemUnitTestText4',
        Label         => 'ZnunyDynamicFieldConfigItemUnitTestText4',
        InternalField => 0,
        ObjectType    => 'Ticket',
        FieldType     => 'Text',
        Config        => {
            DefaultValue => '',
        },
    },
    {
        Name          => 'ZnunyDynamicFieldConfigItemUnitTestText5',
        Label         => 'ZnunyDynamicFieldConfigItemUnitTestText5',
        InternalField => 0,
        ObjectType    => 'Ticket',
        FieldType     => 'Text',
        Config        => {
            DefaultValue => '',
        },
    },
    {
        Name          => 'ZnunyDynamicFieldConfigItemUnitTestDateTime',
        Label         => 'ZnunyDynamicFieldConfigItemUnitTestDateTime',
        InternalField => 0,
        ObjectType    => 'Ticket',
        FieldType     => 'DateTime',
        Config        => {
            DefaultValue => '',
        },
    },
    {
        Name          => 'ZnunyDynamicFieldConfigItemUnitTestDate',
        Label         => 'ZnunyDynamicFieldConfigItemUnitTestDate',
        InternalField => 0,
        ObjectType    => 'Ticket',
        FieldType     => 'Date',
        Config        => {
            DefaultValue => '',
        },
    },
    {
        Name          => 'ZnunyDynamicFieldConfigItemUnitTestMultiselect1',
        Label         => 'ZnunyDynamicFieldConfigItemUnitTestMultiselect1',
        InternalField => 0,
        ObjectType    => 'Ticket',
        FieldType     => 'Multiselect',
        Config        => {
            DefaultValue   => '',
            PossibleNone   => 1,
            PossibleValues => {
                'CPU 1' => 'CPU 1',
                'CPU 2' => 'CPU 2',
                'CPU 3' => 'CPU 3',
            },
        },
    },
    {
        Name          => 'ZnunyDynamicFieldConfigItemUnitTestMultiselect2',
        Label         => 'ZnunyDynamicFieldConfigItemUnitTestMultiselect2',
        InternalField => 0,
        ObjectType    => 'Ticket',
        FieldType     => 'Multiselect',
        Config        => {
            DefaultValue   => '',
            PossibleNone   => 1,
            PossibleValues => {
                'CPU 1' => 'CPU 1',
                'CPU 2' => 'CPU 2',
                'CPU 3' => 'CPU 3',
            },
        },
    },
    {
        Name          => 'ZnunyDynamicFieldConfigItemUnitTestMultiselect3',
        Label         => 'ZnunyDynamicFieldConfigItemUnitTestMultiselect3',
        InternalField => 0,
        ObjectType    => 'Ticket',
        FieldType     => 'Multiselect',
        Config        => {
            DefaultValue   => '',
            PossibleNone   => 1,
            PossibleValues => {
                'CPU 1' => 'CPU 1',
                'CPU 2' => 'CPU 2',
                'CPU 3' => 'CPU 3',
            },
        },
    },
    {
        Name          => 'ZnunyDynamicFieldConfigItemUnitTestDropdown1',
        Label         => 'ZnunyDynamicFieldConfigItemUnitTestDropdown1',
        InternalField => 0,
        ObjectType    => 'Ticket',
        FieldType     => 'Dropdown',
        Config        => {
            DefaultValue   => '',
            PossibleNone   => 1,
            PossibleValues => {
                'CPU 1' => 'CPU 1',
                'CPU 2' => 'CPU 2',
                'CPU 3' => 'CPU 3',
            },
        },
    },
    {
        Name          => 'ZnunyDynamicFieldConfigItemUnitTestDropdown2',
        Label         => 'ZnunyDynamicFieldConfigItemUnitTestDropdown2',
        InternalField => 0,
        ObjectType    => 'Ticket',
        FieldType     => 'Dropdown',
        Config        => {
            DefaultValue   => '',
            PossibleNone   => 1,
            PossibleValues => {
                'CPU 1' => 'CPU 1',
                'CPU 2' => 'CPU 2',
                'CPU 3' => 'CPU 3',
            },
        },
    },
    {
        Name          => 'ZnunyDynamicFieldConfigItemUnitTestDropdown3',
        Label         => 'ZnunyDynamicFieldConfigItemUnitTestDropdown3',
        InternalField => 0,
        ObjectType    => 'Ticket',
        FieldType     => 'Dropdown',
        Config        => {
            DefaultValue   => '',
            PossibleNone   => 1,
            PossibleValues => {
                'CPU 1' => 'CPU 1',
                'CPU 2' => 'CPU 2',
                'CPU 3' => 'CPU 3',
            },
        },
    },

    # ConfigItemDropdown (single select)
    {
        Name          => 'ZnunyDynamicFieldConfigItemUnitTestConfigItem1',
        Label         => 'ZnunyDynamicFieldConfigItemUnitTestConfigItem1',
        InternalField => 0,
        ObjectType    => 'Ticket',
        FieldType     => 'ConfigItemDropdown',
        Config        => {
            ConfigItemClass       => 'Computer',
            ConfigItemLinkType    => undef,
            ConfigItemLinkSource  => undef,
            ConfigItemLinkRemoval => 0,
            AdditionalDFStorage   => [
                {
                    DynamicField  => 'ZnunyDynamicFieldConfigItemUnitTestText1',
                    ConfigItemKey => 'CPU',
                    Type          => 'Frontend',
                },
                {
                    DynamicField  => 'ZnunyDynamicFieldConfigItemUnitTestText2',
                    ConfigItemKey => 'CPU::2',
                    Type          => 'FrontendBackend',
                },
                {
                    DynamicField  => 'ZnunyDynamicFieldConfigItemUnitTestText3',
                    ConfigItemKey => 'Name',
                    Type          => 'FrontendBackend',
                },
                {
                    DynamicField  => 'ZnunyDynamicFieldConfigItemUnitTestText4',
                    ConfigItemKey => 'NIC::1::IPAddress::1',
                    Type          => 'FrontendBackend',
                },
                {
                    DynamicField  => 'ZnunyDynamicFieldConfigItemUnitTestText5',
                    ConfigItemKey => 'ClassID',
                    Type          => 'Backend',                                   # Notice that this one is backend only
                },
                {
                    DynamicField  => 'ZnunyDynamicFieldConfigItemUnitTestDate',
                    ConfigItemKey => 'WarrantyExpirationDate',
                    Type          => 'FrontendBackend',
                },
                {
                    DynamicField  => 'ZnunyDynamicFieldConfigItemUnitTestDateTime',
                    ConfigItemKey => 'WarrantyExpirationDate',
                    Type          => 'FrontendBackend',
                },
                {
                    DynamicField  => 'ZnunyDynamicFieldConfigItemUnitTestDropdown1',
                    ConfigItemKey => 'CPU::1',
                    Type          => 'Frontend',
                },
                {
                    DynamicField  => 'ZnunyDynamicFieldConfigItemUnitTestDropdown2',
                    ConfigItemKey => 'CPU',
                    Type          => 'Backend',
                },
                {
                    DynamicField  => 'ZnunyDynamicFieldConfigItemUnitTestMultiselect1',
                    ConfigItemKey => 'CPU::2',
                    Type          => 'FrontendBackend',
                },
                {
                    DynamicField  => 'ZnunyDynamicFieldConfigItemUnitTestMultiselect2',
                    ConfigItemKey => 'CPU',
                    Type          => 'FrontendBackend',
                },
            ],
        },
    },

    # ConfigItemMultiselect
    {
        Name          => 'ZnunyDynamicFieldConfigItemUnitTestConfigItem2',
        Label         => 'ZnunyDynamicFieldConfigItemUnitTestConfigItem2',
        InternalField => 0,
        ObjectType    => 'Ticket',
        FieldType     => 'ConfigItemMultiselect',
        Config        => {
            ConfigItemClass       => 'Computer',
            ConfigItemLinkType    => undef,
            ConfigItemLinkSource  => undef,
            ConfigItemLinkRemoval => 0,
            AdditionalDFStorage   => [
                {
                    DynamicField  => 'ZnunyDynamicFieldConfigItemUnitTestText1',
                    ConfigItemKey => 'CPU',
                    Type          => 'Backend',
                },
                {
                    DynamicField  => 'ZnunyDynamicFieldConfigItemUnitTestText2',
                    ConfigItemKey => 'CPU::2',
                    Type          => 'FrontendBackend',
                },
                {
                    DynamicField  => 'ZnunyDynamicFieldConfigItemUnitTestText3',
                    ConfigItemKey => 'Name',
                    Type          => 'FrontendBackend',
                },
                {
                    DynamicField  => 'ZnunyDynamicFieldConfigItemUnitTestText4',
                    ConfigItemKey => 'NIC::1::IPAddress::1',
                    Type          => 'FrontendBackend',
                },
                {
                    DynamicField  => 'ZnunyDynamicFieldConfigItemUnitTestText5',
                    ConfigItemKey => 'ClassID',
                    Type          => 'Frontend',                                 # Notice that this one is frontend only
                },
                {
                    DynamicField  => 'ZnunyDynamicFieldConfigItemUnitTestDate',
                    ConfigItemKey => 'WarrantyExpirationDate',
                    Type          => 'Backend',
                },
                {
                    DynamicField  => 'ZnunyDynamicFieldConfigItemUnitTestDateTime',
                    ConfigItemKey => 'WarrantyExpirationDate',
                    Type          => 'Backend',
                },
                {
                    DynamicField  => 'ZnunyDynamicFieldConfigItemUnitTestDropdown1',
                    ConfigItemKey => 'CPU::1',
                    Type          => 'Backend',
                },
                {
                    DynamicField  => 'ZnunyDynamicFieldConfigItemUnitTestDropdown2',
                    ConfigItemKey => 'CPU',
                    Type          => 'Backend',
                },
                {
                    DynamicField  => 'ZnunyDynamicFieldConfigItemUnitTestMultiselect1',
                    ConfigItemKey => 'CPU::2',
                    Type          => 'Backend',
                },
                {
                    DynamicField  => 'ZnunyDynamicFieldConfigItemUnitTestMultiselect2',
                    ConfigItemKey => 'CPU',
                    Type          => 'Backend',
                },
            ],
        },
    },
);

my $DynamicFieldsCreated = $ZnunyHelperObject->_DynamicFieldsCreate(@DynamicFields);

$Self->True(
    scalar $DynamicFieldsCreated,
    'Dynamic fields must have been created successfully.',
);

#
# ConfigItemDropdown (ZnunyDynamicFieldConfigItemUnitTestConfigItem1)
#

my $TicketID = $HelperObject->TicketCreate();

my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
    Name => 'ZnunyDynamicFieldConfigItemUnitTestConfigItem1',
);

# Triggers event Kernel::System::Ticket::Event::ZnunyDynamicFieldConfigItemAdditionalDFStorage
$DynamicFieldBackendObject->ValueSet(
    DynamicFieldConfig => $DynamicFieldConfig,
    ObjectID           => $TicketID,
    Value              => $ConfigItem1ID,
    UserID             => $UserID,
);

# Only additional dynamic fields set to type "backend" are expected to be set by the event.
my %ExpectedDynamicFieldData = (
    ZnunyDynamicFieldConfigItemUnitTestText1        => undef,                    # configured for frontend, not backend
    ZnunyDynamicFieldConfigItemUnitTestText2        => 'CPU 2',
    ZnunyDynamicFieldConfigItemUnitTestText3        => 'Unit test computer 1',
    ZnunyDynamicFieldConfigItemUnitTestText4        => '127.0.0.1',
    ZnunyDynamicFieldConfigItemUnitTestText5        => $ClassList{Computer},
    ZnunyDynamicFieldConfigItemUnitTestDate         => '2040-01-01',
    ZnunyDynamicFieldConfigItemUnitTestDateTime     => '2040-01-01 00:00:00',
    ZnunyDynamicFieldConfigItemUnitTestDropdown1    => undef,                    # configured for frontend, not backend
    ZnunyDynamicFieldConfigItemUnitTestDropdown2    => 'CPU 1',
    ZnunyDynamicFieldConfigItemUnitTestMultiselect1 => [
        'CPU 2',
    ],
    ZnunyDynamicFieldConfigItemUnitTestMultiselect2 => [
        'CPU 1',
        'CPU 2',
    ],
);

my %Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => $UserID,
);

for my $DynamicFieldName ( sort keys %ExpectedDynamicFieldData ) {
    my $ExpectedValue = $ExpectedDynamicFieldData{$DynamicFieldName};

    if ( $DynamicFieldName eq 'ZnunyDynamicFieldConfigItemUnitTestDate' ) {
        $ExpectedValue .= ' 00:00:00';
    }

    $Self->IsDeeply(
        $Ticket{ 'DynamicField_' . $DynamicFieldName },
        $ExpectedValue,
        "ConfigItemDropdown - Content of dynamic field $DynamicFieldName must match expected one.",
    );
}

#
# ConfigItemMultiselect (ZnunyDynamicFieldConfigItemUnitTestConfigItem2)
#

$TicketID = $HelperObject->TicketCreate();

$DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
    Name => 'ZnunyDynamicFieldConfigItemUnitTestConfigItem2',
);

# Triggers event Kernel::System::Ticket::Event::ZnunyDynamicFieldConfigItemAdditionalDFStorage
$DynamicFieldBackendObject->ValueSet(
    DynamicFieldConfig => $DynamicFieldConfig,
    ObjectID           => $TicketID,
    Value              => [ $ConfigItem1ID, $ConfigItem2ID, ],
    UserID             => $UserID,
);

# # Only additional dynamic fields set to type "backend" are expected to be set by the event.
%ExpectedDynamicFieldData = (
    ZnunyDynamicFieldConfigItemUnitTestText1 => 'CPU 1, CPU 2, CPU 1, CPU 4',
    ZnunyDynamicFieldConfigItemUnitTestText2 => 'CPU 2, CPU 4',
    ZnunyDynamicFieldConfigItemUnitTestText3 => 'Unit test computer 1, Unit test computer 2',
    ZnunyDynamicFieldConfigItemUnitTestText4 => '127.0.0.1, 127.0.0.2',
    ZnunyDynamicFieldConfigItemUnitTestText5        => undef,                   # configured for frontend, not backend
    ZnunyDynamicFieldConfigItemUnitTestDate         => '2040-01-01',
    ZnunyDynamicFieldConfigItemUnitTestDateTime     => '2040-01-01 00:00:00',
    ZnunyDynamicFieldConfigItemUnitTestDropdown1    => 'CPU 1',
    ZnunyDynamicFieldConfigItemUnitTestDropdown2    => 'CPU 1',
    ZnunyDynamicFieldConfigItemUnitTestMultiselect1 => [
        'CPU 2',
        'CPU 4',
    ],
    ZnunyDynamicFieldConfigItemUnitTestMultiselect2 => [
        'CPU 1',
        'CPU 2',
        'CPU 1',
        'CPU 4',
    ],
);

%Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => $UserID,
);

for my $DynamicFieldName ( sort keys %ExpectedDynamicFieldData ) {
    my $ExpectedValue = $ExpectedDynamicFieldData{$DynamicFieldName};

    if ( $DynamicFieldName eq 'ZnunyDynamicFieldConfigItemUnitTestDate' ) {
        $ExpectedValue .= ' 00:00:00';
    }

    $Self->IsDeeply(
        $Ticket{ 'DynamicField_' . $DynamicFieldName },
        $ExpectedValue,
        "ConfigItemMultiselect - Content of dynamic field $DynamicFieldName must match expected one.",
    );
}

1;
