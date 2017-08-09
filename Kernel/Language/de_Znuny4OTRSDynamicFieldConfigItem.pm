# --
# Copyright (C) 2012-2017 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_Znuny4OTRSDynamicFieldConfigItem;

use strict;
use warnings;

use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'ConfigItem Multiselect'} = 'ConfigItem Mehrfachauswahl';
    $Self->{Translation}->{'ConfigItem Dropdown'}    = 'ConfigItem Einfachauswahl';
    $Self->{Translation}->{'ConfigItem Class'}       = 'ConfigItem Klasse';

    return 1;
}

1;
