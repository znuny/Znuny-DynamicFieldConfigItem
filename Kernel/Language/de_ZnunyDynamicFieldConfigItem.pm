# --
# Copyright (C) 2012-2022 Znuny GmbH, https://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_ZnunyDynamicFieldConfigItem;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    # Frontend
    $Self->{Translation}->{'Config item'}                   = 'Config-Item';
    $Self->{Translation}->{'Config item (multiselect)'}     = 'Config-Item (Mehrfachauswahl)';
    $Self->{Translation}->{'Config item (dropdown)'}        = 'Config-Item (Einfachauswahl)';
    $Self->{Translation}->{'Config item class'}             = 'Config-Item-Klasse';
    $Self->{Translation}->{'Config item deployment states'} = 'Config-Item-Verwendungsstatus';
    $Self->{Translation}->{'Config item link type'}         = 'Config-Item-Linktyp';
    $Self->{Translation}->{'Config item key'}               = 'Config-Item-Schlüssel';
    $Self->{Translation}->{'Config item link source'}       = 'Config-Item-Linkquelle';
    $Self->{Translation}->{'Config item link removal'}      = 'Config-Item-Links entfernen';
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
    $Self->{Translation}->{'Dynamic field is configured more than once.'}                                            = 'Dynamisches Feld ist mehrmals konfiguriert.';
    $Self->{Translation}->{'Dynamic field does not exist or is invalid.'}                                            = 'Dynamisches Feld existiert nicht oder ist ungültig.';
    $Self->{Translation}->{'Only dynamic fields for tickets are allowed.'}                                           = 'Nur dynamische Ticketfelder sind erlaubt.';

    $Self->{Translation}->{'The selected config item class is invalid or does not exist.'}
        = 'Die gewählte Config-Item-Klasse ist ungültig oder existiert nicht.';

    $Self->{Translation}->{'These dynamic fields will be filled with values of the same selected config item(s).'}
        = 'Diese dynamischen Felder werden mit den Werten aus dem/den gewählten Config-Item(s) befüllt.';

    $Self->{Translation}->{'Select a link type to enable linking between the ticket and the selected config items. Note that linking is only availabe for dynamic fields of tickets.'}
        = 'Wählen Sie einen Linktyp, um die Verknüpfung zwischen Ticket und gewählten Config-Items zu aktivieren. Beachten Sie, dass die Verknüpfung nur für dynamische Felder von Tickets zur Verfügung steht.';

    $Self->{Translation}->{'Activate this option to remove links between the ticket and config items removed from this field.'}
        = 'Aktivieren Sie diese Option, um Verknüpfungen zwischen Ticket und Config-Items zu entfernen, die aus diesem Feld entfernt wurden.';

    # SysConfig
    $Self->{Translation}->{"Frontend module registration for the agent interface."}                                       = "Registrierung des Frontend-Moduls für die Agentenschnittstelle.";
    $Self->{Translation}->{"Creates a link between ticket and config item after setting the value in the dynamic field."} = "Erstellt einen Link zwischen Ticket und Config-Item nach dem Setzen des Wertes im dynamischen Feld.";
    $Self->{Translation}->{"Link type between ticket and config item."}                                                   = "Linktyp zwischen Ticket und Config-Item.";
    $Self->{Translation}->{"Ticket event module that creates and removes links between tickets and config items."}        = "Ticket-Event-Modul, das Links zwischen Tickets und Config-Items erstellt und entfernt.";

    $Self->{Translation}->{"AlternativeTo"} = "Alternativ zu";
    $Self->{Translation}->{"DependsOn"}     = "Hängt ab von";
    $Self->{Translation}->{"RelevantTo"}    = "Relevant für";

    $Self->{Translation}->{'No longer in use. Do not change. Required due to compatibility with previous package versions.'}
        = 'Nicht mehr in Verwendung. Nicht ändern. Notwendig wg. Kompatibilität zu vorherigen Paketversionen.';

    $Self->{Translation}->{'Frontend and Backend'} = 'Oberfläche und Backend';
    $Self->{Translation}->{'Add dynamic field'}    = 'Dynamisches Feld hinzufügen';

    return 1;
}

1;
