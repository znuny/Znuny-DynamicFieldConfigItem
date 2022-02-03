# --
# Copyright (C) 2012-2021 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Ticket::Event::ZnunyDynamicFieldConfigItemTicketLink;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
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
    my $LinkObject         = $Kernel::OM->Get('Kernel::System::LinkObject');
    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');

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

    my %ValidDynamicFieldTypes = (
        ConfigItemDropdown    => 1,
        ConfigItemMultiselect => 1,
    );

    my $DynamicField = $DynamicFieldObject->DynamicFieldGet(
        Name => $Param{Data}->{FieldName}
    );
    return if !$ValidDynamicFieldTypes{ $DynamicField->{FieldType} };

    # Skip, if no link type is configured.
    my $LinkType = $DynamicField->{Config}->{ConfigItemLinkType};
    return if !$LinkType;

    my $TicketID = $Param{Data}->{TicketID};

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

    my $SourceObject = $DynamicField->{Config}->{ConfigItemLinkSource};
    my $SourceKey;
    my $TargetObject;
    my $TargetKey;

    if ( $SourceObject eq 'ITSMConfigItem' ) {
        $TargetObject = $DynamicField->{ObjectType};
        $TargetKey    = $TicketID;
    }
    else {
        $SourceKey    = $TicketID;
        $TargetObject = 'ITSMConfigItem';
    }

    # Remove links for removed config items (only if activated).
    my $ConfigItemLinkRemoval = $DynamicField->{Config}->{ConfigItemLinkRemoval};
    if ( @OldValues && $ConfigItemLinkRemoval ) {
        my @DeselectedConfigItemIDs;

        CONFIGITEMID:
        for my $ConfigItemID (@OldValues) {
            my $ConfigItemIDStillSelected = grep { $ConfigItemID eq $_ } @NewValues;
            next CONFIGITEMID if $ConfigItemIDStillSelected;

            push @DeselectedConfigItemIDs, $ConfigItemID;
        }

        CONFIGITEMID:
        for my $ConfigItemID (@DeselectedConfigItemIDs) {
            next CONFIGITEMID if !$LinkList->{ITSMConfigItem}->{$LinkType}->{Source}->{$ConfigItemID}
                && !$LinkList->{ITSMConfigItem}->{$LinkType}->{Target}->{$ConfigItemID};

            if ( $SourceObject eq 'ITSMConfigItem' ) {
                $SourceKey = $ConfigItemID;
            }
            else {
                $TargetKey = $ConfigItemID;
            }

            $LinkObject->LinkDelete(
                Object1 => $SourceObject,
                Key1    => $SourceKey,
                Object2 => $TargetObject,
                Key2    => $TargetKey,
                Type    => $LinkType,
                UserID  => 1,
            );
        }
    }

    # Add links for added config items.
    CONFIGITEMID:
    for my $ConfigItemID (@NewValues) {
        next CONFIGITEMID if $LinkList->{ITSMConfigItem}->{$LinkType}->{Source}->{$ConfigItemID};

        if ( $SourceObject eq 'ITSMConfigItem' ) {
            $SourceKey = $ConfigItemID;
        }
        else {
            $TargetKey = $ConfigItemID;
        }

        $LinkObject->LinkAdd(
            SourceObject => $SourceObject,
            SourceKey    => $SourceKey,
            TargetObject => $TargetObject,
            TargetKey    => $TargetKey,
            Type         => $LinkType,
            State        => 'Valid',
            UserID       => 1,
        );
    }

    return 1;
}

1;
