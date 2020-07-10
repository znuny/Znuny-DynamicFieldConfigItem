# --
# Copyright (C) 2012-2020 Znuny GmbH, http://znuny.com/
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

my $HelperObject                           = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ConfigItemObject                       = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
my $GeneralCatalogObject                   = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
my $DynamicFieldObject                     = $Kernel::OM->Get('Kernel::System::DynamicField');
my $DynamicFieldBackendObject              = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
my $ValidObject                            = $Kernel::OM->Get('Kernel::System::Valid');
my $TicketObject                           = $Kernel::OM->Get('Kernel::System::Ticket');
my $ZnunyHelperObject                      = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $Znuny4OTRSDynamicFieldConfigItemObject = $Kernel::OM->Get('Kernel::System::Znuny4OTRSDynamicFieldConfigItem');

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
        Name          => 'Znuny4OTRSDynamicFieldConfigItemUnitTestText1',
        Label         => 'Znuny4OTRSDynamicFieldConfigItemUnitTestText1',
        InternalField => 0,
        ObjectType    => 'Ticket',
        FieldType     => 'Text',
        Config        => {
            DefaultValue => '',
        },
    },
    {
        Name          => 'Znuny4OTRSDynamicFieldConfigItemUnitTestText2',
        Label         => 'Znuny4OTRSDynamicFieldConfigItemUnitTestText2',
        InternalField => 0,
        ObjectType    => 'Ticket',
        FieldType     => 'Text',
        Config        => {
            DefaultValue => '',
        },
    },
    {
        Name          => 'Znuny4OTRSDynamicFieldConfigItemUnitTestText3',
        Label         => 'Znuny4OTRSDynamicFieldConfigItemUnitTestText3',
        InternalField => 0,
        ObjectType    => 'Ticket',
        FieldType     => 'Text',
        Config        => {
            DefaultValue => '',
        },
    },
    {
        Name          => 'Znuny4OTRSDynamicFieldConfigItemUnitTestText4',
        Label         => 'Znuny4OTRSDynamicFieldConfigItemUnitTestText4',
        InternalField => 0,
        ObjectType    => 'Ticket',
        FieldType     => 'Text',
        Config        => {
            DefaultValue => '',
        },
    },
    {
        Name          => 'Znuny4OTRSDynamicFieldConfigItemUnitTestText5',
        Label         => 'Znuny4OTRSDynamicFieldConfigItemUnitTestText5',
        InternalField => 0,
        ObjectType    => 'Ticket',
        FieldType     => 'Text',
        Config        => {
            DefaultValue => '',
        },
    },
    {
        Name          => 'Znuny4OTRSDynamicFieldConfigItemUnitTestDateTime',
        Label         => 'Znuny4OTRSDynamicFieldConfigItemUnitTestDateTime',
        InternalField => 0,
        ObjectType    => 'Ticket',
        FieldType     => 'DateTime',
        Config        => {
            DefaultValue => '',
        },
    },
    {
        Name          => 'Znuny4OTRSDynamicFieldConfigItemUnitTestDate',
        Label         => 'Znuny4OTRSDynamicFieldConfigItemUnitTestDate',
        InternalField => 0,
        ObjectType    => 'Ticket',
        FieldType     => 'Date',
        Config        => {
            DefaultValue => '',
        },
    },
    {
        Name          => 'Znuny4OTRSDynamicFieldConfigItemUnitTestMultiselect1',
        Label         => 'Znuny4OTRSDynamicFieldConfigItemUnitTestMultiselect1',
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
        Name          => 'Znuny4OTRSDynamicFieldConfigItemUnitTestMultiselect2',
        Label         => 'Znuny4OTRSDynamicFieldConfigItemUnitTestMultiselect2',
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
        Name          => 'Znuny4OTRSDynamicFieldConfigItemUnitTestMultiselect3',
        Label         => 'Znuny4OTRSDynamicFieldConfigItemUnitTestMultiselect3',
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
        Name          => 'Znuny4OTRSDynamicFieldConfigItemUnitTestDropdown1',
        Label         => 'Znuny4OTRSDynamicFieldConfigItemUnitTestDropdown1',
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
        Name          => 'Znuny4OTRSDynamicFieldConfigItemUnitTestDropdown2',
        Label         => 'Znuny4OTRSDynamicFieldConfigItemUnitTestDropdown2',
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
        Name          => 'Znuny4OTRSDynamicFieldConfigItemUnitTestDropdown3',
        Label         => 'Znuny4OTRSDynamicFieldConfigItemUnitTestDropdown3',
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
        Name          => 'Znuny4OTRSDynamicFieldConfigItemUnitTestConfigItem1',
        Label         => 'Znuny4OTRSDynamicFieldConfigItemUnitTestConfigItem1',
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
                    DynamicField  => 'Znuny4OTRSDynamicFieldConfigItemUnitTestText1',
                    ConfigItemKey => 'CPU',
                    Type          => 'Frontend',
                },
                {
                    DynamicField  => 'Znuny4OTRSDynamicFieldConfigItemUnitTestText2',
                    ConfigItemKey => 'CPU::2',
                    Type          => 'FrontendBackend',
                },
                {
                    DynamicField  => 'Znuny4OTRSDynamicFieldConfigItemUnitTestText3',
                    ConfigItemKey => 'Name',
                    Type          => 'FrontendBackend',
                },
                {
                    DynamicField  => 'Znuny4OTRSDynamicFieldConfigItemUnitTestText4',
                    ConfigItemKey => 'NIC::1::IPAddress::1',
                    Type          => 'FrontendBackend',
                },
                {
                    DynamicField  => 'Znuny4OTRSDynamicFieldConfigItemUnitTestText5',
                    ConfigItemKey => 'ClassID',
                    Type => 'Backend',    # Notice that this one is backend only
                },
                {
                    DynamicField  => 'Znuny4OTRSDynamicFieldConfigItemUnitTestDate',
                    ConfigItemKey => 'WarrantyExpirationDate',
                    Type          => 'FrontendBackend',
                },
                {
                    DynamicField  => 'Znuny4OTRSDynamicFieldConfigItemUnitTestDateTime',
                    ConfigItemKey => 'WarrantyExpirationDate',
                    Type          => 'FrontendBackend',
                },
                {
                    DynamicField  => 'Znuny4OTRSDynamicFieldConfigItemUnitTestDropdown1',
                    ConfigItemKey => 'CPU::1',
                    Type          => 'Frontend',
                },
                {
                    DynamicField  => 'Znuny4OTRSDynamicFieldConfigItemUnitTestDropdown2',
                    ConfigItemKey => 'CPU',
                    Type          => 'Backend',
                },
                {
                    DynamicField  => 'Znuny4OTRSDynamicFieldConfigItemUnitTestMultiselect1',
                    ConfigItemKey => 'CPU::2',
                    Type          => 'FrontendBackend',
                },
                {
                    DynamicField  => 'Znuny4OTRSDynamicFieldConfigItemUnitTestMultiselect2',
                    ConfigItemKey => 'CPU',
                    Type          => 'FrontendBackend',
                },
            ],
        },
    },

    # ConfigItemMultiselect
    {
        Name          => 'Znuny4OTRSDynamicFieldConfigItemUnitTestConfigItem2',
        Label         => 'Znuny4OTRSDynamicFieldConfigItemUnitTestConfigItem2',
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
                    DynamicField  => 'Znuny4OTRSDynamicFieldConfigItemUnitTestText1',
                    ConfigItemKey => 'CPU',
                    Type          => 'Backend',
                },
                {
                    DynamicField  => 'Znuny4OTRSDynamicFieldConfigItemUnitTestText2',
                    ConfigItemKey => 'CPU::2',
                    Type          => 'FrontendBackend',
                },
                {
                    DynamicField  => 'Znuny4OTRSDynamicFieldConfigItemUnitTestText3',
                    ConfigItemKey => 'Name',
                    Type          => 'FrontendBackend',
                },
                {
                    DynamicField  => 'Znuny4OTRSDynamicFieldConfigItemUnitTestText4',
                    ConfigItemKey => 'NIC::1::IPAddress::1',
                    Type          => 'FrontendBackend',
                },
                {
                    DynamicField  => 'Znuny4OTRSDynamicFieldConfigItemUnitTestText5',
                    ConfigItemKey => 'ClassID',
                    Type => 'Frontend',    # Notice that this one is frontend only
                },
                {
                    DynamicField  => 'Znuny4OTRSDynamicFieldConfigItemUnitTestDate',
                    ConfigItemKey => 'WarrantyExpirationDate',
                    Type          => 'Backend',
                },
                {
                    DynamicField  => 'Znuny4OTRSDynamicFieldConfigItemUnitTestDateTime',
                    ConfigItemKey => 'WarrantyExpirationDate',
                    Type          => 'Backend',
                },
                {
                    DynamicField  => 'Znuny4OTRSDynamicFieldConfigItemUnitTestDropdown1',
                    ConfigItemKey => 'CPU::1',
                    Type          => 'Backend',
                },
                {
                    DynamicField  => 'Znuny4OTRSDynamicFieldConfigItemUnitTestDropdown2',
                    ConfigItemKey => 'CPU',
                    Type          => 'Backend',
                },
                {
                    DynamicField  => 'Znuny4OTRSDynamicFieldConfigItemUnitTestMultiselect1',
                    ConfigItemKey => 'CPU::2',
                    Type          => 'Backend',
                },
                {
                    DynamicField  => 'Znuny4OTRSDynamicFieldConfigItemUnitTestMultiselect2',
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
# ConfigItemDropdown (Znuny4OTRSDynamicFieldConfigItemUnitTestConfigItem1)
#

my $TicketID = $HelperObject->TicketCreate();

my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
    Name => 'Znuny4OTRSDynamicFieldConfigItemUnitTestConfigItem1',
);

# Triggers event Kernel::System::Ticket::Event::Znuny4OTRSDynamicFieldConfigItemAdditionalDFStorage
$DynamicFieldBackendObject->ValueSet(
    DynamicFieldConfig => $DynamicFieldConfig,
    ObjectID           => $TicketID,
    Value              => $ConfigItem1ID,
    UserID             => $UserID,
);

# Only additional dynamic fields set to type "backend" are expected to be set by the event.
my %ExpectedDynamicFieldData = (
    Znuny4OTRSDynamicFieldConfigItemUnitTestText1     => undef,                   # configured for frontend, not backend
    Znuny4OTRSDynamicFieldConfigItemUnitTestText2     => 'CPU 2',
    Znuny4OTRSDynamicFieldConfigItemUnitTestText3     => 'Unit test computer 1',
    Znuny4OTRSDynamicFieldConfigItemUnitTestText4     => '127.0.0.1',
    Znuny4OTRSDynamicFieldConfigItemUnitTestText5     => $ClassList{Computer},
    Znuny4OTRSDynamicFieldConfigItemUnitTestDate      => '2040-01-01',
    Znuny4OTRSDynamicFieldConfigItemUnitTestDateTime  => '2040-01-01 00:00:00',
    Znuny4OTRSDynamicFieldConfigItemUnitTestDropdown1 => undef,                   # configured for frontend, not backend
    Znuny4OTRSDynamicFieldConfigItemUnitTestDropdown2 => 'CPU 1',
    Znuny4OTRSDynamicFieldConfigItemUnitTestMultiselect1 => [
        'CPU 2',
    ],
    Znuny4OTRSDynamicFieldConfigItemUnitTestMultiselect2 => [
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

    if ( $DynamicFieldName eq 'Znuny4OTRSDynamicFieldConfigItemUnitTestDate' ) {
        $ExpectedValue .= ' 00:00:00';
    }

    $Self->IsDeeply(
        $Ticket{ 'DynamicField_' . $DynamicFieldName },
        $ExpectedValue,
        "Content of dynamic field $DynamicFieldName must match expected one.",
    );
}

#
# ConfigItemMultiselect (Znuny4OTRSDynamicFieldConfigItemUnitTestConfigItem2)
#

$TicketID = $HelperObject->TicketCreate();

$DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
    Name => 'Znuny4OTRSDynamicFieldConfigItemUnitTestConfigItem2',
);

# Triggers event Kernel::System::Ticket::Event::Znuny4OTRSDynamicFieldConfigItemAdditionalDFStorage
$DynamicFieldBackendObject->ValueSet(
    DynamicFieldConfig => $DynamicFieldConfig,
    ObjectID           => $TicketID,
    Value              => [ $ConfigItem1ID, $ConfigItem2ID, ],
    UserID             => $UserID,
);

# # Only additional dynamic fields set to type "backend" are expected to be set by the event.
%ExpectedDynamicFieldData = (
    Znuny4OTRSDynamicFieldConfigItemUnitTestText1 => 'CPU 1, CPU 2, CPU 4',
    Znuny4OTRSDynamicFieldConfigItemUnitTestText2 => 'CPU 2, CPU 4',
    Znuny4OTRSDynamicFieldConfigItemUnitTestText3 => 'Unit test computer 1, Unit test computer 2',
    Znuny4OTRSDynamicFieldConfigItemUnitTestText4 => '127.0.0.1, 127.0.0.2',
    Znuny4OTRSDynamicFieldConfigItemUnitTestText5        => undef,                # configured for frontend, not backend
    Znuny4OTRSDynamicFieldConfigItemUnitTestDate         => '2040-01-01',
    Znuny4OTRSDynamicFieldConfigItemUnitTestDateTime     => '2040-01-01 00:00:00',
    Znuny4OTRSDynamicFieldConfigItemUnitTestDropdown1    => 'CPU 1',
    Znuny4OTRSDynamicFieldConfigItemUnitTestDropdown2    => 'CPU 1',
    Znuny4OTRSDynamicFieldConfigItemUnitTestMultiselect1 => [
        'CPU 2',
        'CPU 4',
    ],
    Znuny4OTRSDynamicFieldConfigItemUnitTestMultiselect2 => [
        'CPU 1',
        'CPU 2',
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

    if ( $DynamicFieldName eq 'Znuny4OTRSDynamicFieldConfigItemUnitTestDate' ) {
        $ExpectedValue .= ' 00:00:00';
    }

    $Self->IsDeeply(
        $Ticket{ 'DynamicField_' . $DynamicFieldName },
        $ExpectedValue,
        "Content of dynamic field $DynamicFieldName must match expected one.",
    );
}

1;
