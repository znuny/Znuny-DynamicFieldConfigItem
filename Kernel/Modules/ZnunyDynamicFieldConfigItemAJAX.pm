# --
# Copyright (C) 2012 Znuny GmbH, https://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::ZnunyDynamicFieldConfigItemAJAX;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Log',
    'Kernel::System::Web::Request',
    'Kernel::System::ZnunyDynamicFieldConfigItem',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject                         = $Kernel::OM->Get('Kernel::System::Log');
    my $LayoutObject                      = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject                       = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $ZnunyDynamicFieldConfigItemObject = $Kernel::OM->Get('Kernel::System::ZnunyDynamicFieldConfigItem');

    if ( !$Self->{Subaction} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Parameter Subaction is missing.',
        );

        return;
    }

    my $Data;

    # TODO: we should use the same naming like DF-LDAP (AutoFill) or standardize these
    if ( $Self->{Subaction} eq 'GetAdditionalDFStorageData' ) {
        my $SourceDynamicFieldName = $ParamObject->GetParam( Param => 'SourceDynamicFieldName' );
        if ( !defined $SourceDynamicFieldName || !length $SourceDynamicFieldName ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => 'Parameter SourceDynamicFieldName is missing.',
            );

            return;
        }

        my @SelectedConfigItemIDs = $ParamObject->GetArray(
            Param => 'SelectedConfigItemIDs[]',
            Raw   => 1,
        );

        # If no config item IDs were given, the array contains one element with an empty string.
        # Remove it.
        @SelectedConfigItemIDs = grep { defined $_ && length $_ } @SelectedConfigItemIDs;

        $Data = $ZnunyDynamicFieldConfigItemObject->GetAdditionalDFStorageData(
            SourceDynamicFieldName => $SourceDynamicFieldName,
            SelectedConfigItemIDs  => \@SelectedConfigItemIDs,
            StorageType            => 'Frontend',
            UserID                 => $Self->{UserID},
        );
    }

    my $JSON = $LayoutObject->JSONEncode(
        Data => $Data,
    );

    return $LayoutObject->Attachment(
        ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
        Content     => $JSON // '[]',
        Type        => 'inline',
        NoCache     => 1,
    );
}

1;
