# --
# Copyright (C) 2012-2019 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Ticket::Event::Znuny4OTRSDynamicFieldConfigItem;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::DynamicField',
    'Kernel::System::LinkObject',
    'Kernel::System::Log',
    'Kernel::System::Ticket',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject          = $Kernel::OM->Get('Kernel::System::Log');
    my $TicketObject       = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ConfigObject       = $Kernel::OM->Get('Kernel::Config');
    my $LinkObject         = $Kernel::OM->Get('Kernel::System::LinkObject');
    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');

    my $Config = $ConfigObject->Get('Znuny4OTRSDynamicFieldConfigItem');
    return if !$Config->{TicketLink};

    NEEDED:
    for my $Needed (qw( Data Event Config UserID )) {
        next NEEDED if $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Need $Needed!"
        );
        return;
    }

    NEEDED:
    for my $Needed (qw( TicketID )) {
        next NEEDED if $Param{Data}->{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Need $Needed in Data!"
        );
        return;
    }

    my $DynamicField = $DynamicFieldObject->DynamicFieldGet(
        Name => $Param{Data}->{FieldName}
    );
    return
        if $DynamicField->{FieldType} ne 'ConfigItemMultiselect' && $DynamicField->{FieldType} ne 'ConfigItemDropdown';

    my $TicketID = $Param{Data}->{TicketID};
    my $LinkType = $Config->{LinkType} || 'RelevantTo';

    my $LinkList = $LinkObject->LinkList(
        Object  => 'Ticket',
        Key     => $TicketID,
        Object2 => 'ITSMConfigItem',
        State   => 'Valid',
        UserID  => 1,
    );

    my @NewValues;
    if ( ref $Param{Data}->{Value} eq 'ARRAY' ) {
        @NewValues = @{ $Param{Data}->{Value} };
    }
    else {
        @NewValues = $Param{Data}->{Value};
    }

    my @OldValues;
    if ( $Param{Data}->{OldValue} && ref $Param{Data}->{OldValue} eq 'ARRAY' ) {
        @OldValues = @{ $Param{Data}->{OldValue} };
    }
    elsif ( $Param{Data}->{OldValue} ) {
        @OldValues = $Param{Data}->{OldValue};
    }

    if (@OldValues) {
        my @NewOldValues;

        VALUE:
        for my $Value (@OldValues) {
            my $Exists = grep { $Value eq $_ } @NewValues;
            next VALUE if $Exists;

            push @NewOldValues, $Value;

        }

        CONFIGITEM:
        for my $ConfigItemID (@NewOldValues) {
            next CONFIGITEM if !$LinkList->{ITSMConfigItem}->{$LinkType}->{Source}->{$ConfigItemID};

            $LinkObject->LinkDelete(
                Object1 => 'ITSMConfigItem',
                Key1    => $ConfigItemID,
                Object2 => 'Ticket',
                Key2    => $TicketID,
                Type    => $LinkType,
                UserID  => 1,
            );
        }
    }

    CONFIGITEM:
    for my $ConfigItemID (@NewValues) {
        next CONFIGITEM if $LinkList->{ITSMConfigItem}->{$LinkType}->{Source}->{$ConfigItemID};

        $LinkObject->LinkAdd(
            SourceObject => 'ITSMConfigItem',
            SourceKey    => $ConfigItemID,
            TargetObject => 'Ticket',
            TargetKey    => $TicketID,
            Type         => $LinkType,
            State        => 'Valid',
            UserID       => 1,
        );
    }

    return 1;
}

1;
