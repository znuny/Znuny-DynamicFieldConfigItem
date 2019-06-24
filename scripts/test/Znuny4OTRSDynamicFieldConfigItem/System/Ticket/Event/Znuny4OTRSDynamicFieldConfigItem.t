# --
# Copyright (C) 2012-2019 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::System::VariableCheck qw(:all);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $HelperObject                 = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $TicketObject                 = $Kernel::OM->Get('Kernel::System::Ticket');
my $ZnunyHelperObject            = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $UnitTestITSMConfigItemObject = $Kernel::OM->Get('Kernel::System::UnitTest::ITSMConfigItem');
my $DynamicFieldObject           = $Kernel::OM->Get('Kernel::System::DynamicField');
my $DynamicFieldBackendObject    = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
my $LinkObject                   = $Kernel::OM->Get('Kernel::System::LinkObject');

my @DynamicFields = (
    {
        Name          => 'ConfigItemDropdown',
        Label         => "ConfigItemDropdown",
        InternalField => 0,
        ObjectType    => 'Ticket',
        FieldType     => 'ConfigItemDropdown',
        Config        => {
            ConfigItemClass       => 'Computer',
            ConfigItemLinkType    => 'DependsOn',
            ConfigItemLinkSource  => 'Ticket',
            ConfigItemLinkRemoval => 0,
        },
    },
    {
        Name          => 'ConfigItemMultiselect',
        Label         => "ConfigItemMultiselect",
        InternalField => 0,
        ObjectType    => 'Ticket',
        FieldType     => 'ConfigItemMultiselect',
        Config        => {
            ConfigItemClass       => 'Computer',
            ConfigItemLinkType    => 'AlternativeTo',
            ConfigItemLinkSource  => 'ITSMConfigItem',
            ConfigItemLinkRemoval => 1,
        },
    },
);

$ZnunyHelperObject->_DynamicFieldsCreate(@DynamicFields);

my %DynamicFieldConfig;
for my $DynamicField (qw(ConfigItemDropdown ConfigItemMultiselect)) {
    $DynamicFieldConfig{$DynamicField} = $DynamicFieldObject->DynamicFieldGet(
        Name => $DynamicField,
    );

}

my $TicketID = $HelperObject->TicketCreate();

my %Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
);

$Self->Is(
    $Ticket{DynamicField_ConfigItemDropdown},
    undef,
    'ConfigItemDropdown',
);

$Self->Is(
    $Ticket{DynamicField_ConfigItemMultiselect},
    undef,
    'ConfigItemMultiselect',
);

my $Version1 = $UnitTestITSMConfigItemObject->ConfigItemCreate(
    Name          => 'DynamicField ConfigItemDropdown Test 1',
    ClassName     => 'Computer',
    DeplStateName => 'Production',
    InciStateName => 'Operational',
    XMLData       => {
        OtherEquipment         => '...',
        Note                   => '...',
        SerialNumber           => '...',
        WarrantyExpirationDate => '2016-01-01',
        InstallDate            => '2016-01-01',
    },
);

my $Version2 = $UnitTestITSMConfigItemObject->ConfigItemCreate(
    Name          => 'DynamicField ConfigItemMultiselect Test 2',
    ClassName     => 'Computer',
    DeplStateName => 'Production',
    InciStateName => 'Operational',
    XMLData       => {
        OtherEquipment         => '...',
        Note                   => '...',
        SerialNumber           => '...',
        WarrantyExpirationDate => '2016-01-01',
        InstallDate            => '2016-01-01',
    },
);

my $Version3 = $UnitTestITSMConfigItemObject->ConfigItemCreate(
    Name          => 'DynamicField ConfigItemMultiselect Test 3',
    ClassName     => 'Computer',
    DeplStateName => 'Production',
    InciStateName => 'Operational',
    XMLData       => {
        OtherEquipment         => '...',
        Note                   => '...',
        SerialNumber           => '...',
        WarrantyExpirationDate => '2016-01-01',
        InstallDate            => '2016-01-01',
    },
);

$DynamicFieldBackendObject->ValueSet(
    DynamicFieldConfig => $DynamicFieldConfig{'ConfigItemDropdown'},
    ObjectID           => $TicketID,
    Value              => $Version1->{ConfigItemID},
    UserID             => 1,
);

my @Values = (
    $Version1->{ConfigItemID},
    $Version2->{ConfigItemID},
);

$DynamicFieldBackendObject->ValueSet(
    DynamicFieldConfig => $DynamicFieldConfig{'ConfigItemMultiselect'},
    ObjectID           => $TicketID,
    UserID             => 1,
    Value              => \@Values,
);

$Kernel::OM->ObjectsDiscard(
    Objects => ['Kernel::System::Ticket'],
);

$TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

%Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
);

$Self->Is(
    $Ticket{DynamicField_ConfigItemDropdown},
    $Version1->{ConfigItemID},
    'ConfigItemDropdown',
);

$Self->IsDeeply(
    $Ticket{DynamicField_ConfigItemMultiselect},
    \@Values,
    'ConfigItemMultiselect',
);

my $LinkList = $LinkObject->LinkList(
    Object  => 'Ticket',
    Key     => $TicketID,
    Object2 => 'ITSMConfigItem',
    State   => 'Valid',
    UserID  => 1,
);

$Self->IsDeeply(
    $LinkList,
    {
        ITSMConfigItem => {
            DependsOn => {
                Target => {
                    $Version1->{ConfigItemID} => 1,
                },
            },
            AlternativeTo => {
                Source => {
                    $Version1->{ConfigItemID} => 1,
                    $Version2->{ConfigItemID} => 1,
                },
            },
        },
    },
    'LinkList',
);

$Kernel::OM->ObjectsDiscard(
    Objects => ['Kernel::System::Ticket'],
);

$TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

# change ConfigItems again
$DynamicFieldBackendObject->ValueSet(
    DynamicFieldConfig => $DynamicFieldConfig{'ConfigItemDropdown'},
    ObjectID           => $TicketID,
    Value              => $Version2->{ConfigItemID},
    UserID             => 1,
);

@Values = (
    $Version1->{ConfigItemID},
    $Version3->{ConfigItemID},
);

$DynamicFieldBackendObject->ValueSet(
    DynamicFieldConfig => $DynamicFieldConfig{'ConfigItemMultiselect'},
    ObjectID           => $TicketID,
    UserID             => 1,
    Value              => \@Values,
);

$Kernel::OM->ObjectsDiscard(
    Objects => ['Kernel::System::Ticket'],
);

$TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

%Ticket = $TicketObject->TicketGet(
    TicketID      => $TicketID,
    DynamicFields => 1,
    UserID        => 1,
);

$Self->Is(
    $Ticket{DynamicField_ConfigItemDropdown},
    $Version2->{ConfigItemID},
    'ConfigItemDropdown',
);

$Self->IsDeeply(
    $Ticket{DynamicField_ConfigItemMultiselect},
    \@Values,
    'ConfigItemMultiselect',
);

$LinkList = $LinkObject->LinkList(
    Object  => 'Ticket',
    Key     => $TicketID,
    Object2 => 'ITSMConfigItem',
    State   => 'Valid',
    UserID  => 1,
);

$Self->IsDeeply(
    $LinkList,
    {
        ITSMConfigItem => {
            DependsOn => {
                Target => {
                    $Version2->{ConfigItemID} => 1,

                    # Because dropdown field is configured to not remove links to removed config items.
                    $Version1->{ConfigItemID} => 1,
                },
            },
            AlternativeTo => {
                Source => {
                    $Version1->{ConfigItemID} => 1,
                    $Version3->{ConfigItemID} => 1,
                },
            },
        },
    },
    'LinkList',
);

1;
