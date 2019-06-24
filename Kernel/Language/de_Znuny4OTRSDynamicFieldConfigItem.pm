# --
# Copyright (C) 2012-2019 Znuny GmbH, http://znuny.com/
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

    # Frontend
    $Self->{Translation}->{'Config item (multiselect)'}     = 'Config-Item (Mehrfachauswahl)';
    $Self->{Translation}->{'Config item (dropdown)'}        = 'Config-Item (Einfachauswahl)';
    $Self->{Translation}->{'Config item class'}             = 'Config-Item-Klasse';
    $Self->{Translation}->{'Config item deployment states'} = 'Config-Item-Verwendungsstatus';
    $Self->{Translation}->{'Add %s field'}                  = 'Feld %s hinzufügen';
    $Self->{Translation}->{'Change %s field'}               = 'Feld %s ändern';

    $Self->{Translation}->{"Changing this value will require manual changes in the system."} = "Die Änderung dieses Wertes erfordert manuelle Änderungen im System.";

    $Self->{Translation}->{"Dynamic Fields"}      = "Dynamische Felder";
    $Self->{Translation}->{"Field Settings"}      = "Feldeinstellungen";
    $Self->{Translation}->{"Field order"}         = "Feldreihenfolge";
    $Self->{Translation}->{"Field type"}          = "Feldtyp";
    $Self->{Translation}->{"General"}             = "Allgemeines";
    $Self->{Translation}->{"Go back to overview"} = "Zurück zur Übersicht";
    $Self->{Translation}->{"Internal field"}      = "Internes Feld";

    $Self->{Translation}->{"Must be unique and only accepts alphanumeric characters."}                               = "Muss eindeutig sein und darf nur alphanumerische Zeichen enthalten.";
    $Self->{Translation}->{"Object type"}                                                                            = "Objekttyp";
    $Self->{Translation}->{"This field is protected and can't be deleted."}                                          = "Dieses Feld ist geschützt und kann nicht gelöscht werden.";
    $Self->{Translation}->{"This field is required and must be numeric."}                                            = "Dieses Feld ist erforderlich und muss numerisch sein.";
    $Self->{Translation}->{"This field is required and the value must be alphanumeric."}                             = "Dieses Feld ist erforderlich und der Wert muss alphanumerisch sein.";
    $Self->{Translation}->{"This field is required."}                                                                = "Dies ist ein Pflichtfeld.";
    $Self->{Translation}->{"This is the name to be shown on the screens where the field is active."}                 = "Dies ist der Name, der in den Dialogen angezeigt werden soll, in denen das Feld aktiv ist.";
    $Self->{Translation}->{"This is the order in which this field will be shown on the screens where it is active."} = "Dies ist die Reihenfolge, in der dieses Feld in den aktiven Dialogen angezeigt wird.";

    # SysConfig
    $Self->{Translation}->{"Frontend module registration for the agent interface."}                                       = "Registrierung des Frontend-Moduls für die Agentenschnittstelle.";
    $Self->{Translation}->{"Creates a link between ticket and config item after setting the value in the dynamic field."} = "Erstellt einen Link zwischen Ticket und Config-Item nach dem Setzen des Wertes im dynamischen Feld.";
    $Self->{Translation}->{"Link type between ticket and config item."}                                                   = "Linktyp zwischen Ticket und Config-Item.";
    $Self->{Translation}->{"Ticket event module that creates and removes links between tickets and config items."}        = "Ticket-Event-Modul, das Links zwischen Tickets und Config-Items erstellt und entfernt.";

    $Self->{Translation}->{"AlternativeTo"} = "Alternativ zu";
    $Self->{Translation}->{"DependsOn"}     = "Hängt ab von";
    $Self->{Translation}->{"RelevantTo"}    = "Relevant für";

    return 1;
}

1;
