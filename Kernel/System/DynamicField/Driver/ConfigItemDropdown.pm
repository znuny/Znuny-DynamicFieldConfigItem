# --
# Copyright (C) 2012-2020 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::DynamicField::Driver::ConfigItemDropdown;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

use parent qw(
    Kernel::System::DynamicField::Driver::ConfigItem
    Kernel::System::DynamicField::Driver::Dropdown
);

1;
