# Funktionalität

Dieses Paket ergänzt OTRS um dynamische Feldtypen für Config-Items.

Die folgenden Typen werden ergänzt:

- Config-Item-Einfachauswahl
- Config-Item-Mehrfachauswahl

In dynamischen Feldern dieser Typen stehen alle Config-Items zur Auswahl, die zur konfigurierten Klasse gehören. Dabei ist zu beachten, dass diese dynamischen Felder nur mit Config-Item-Klassen eingesetzt werden sollten, die weniger als 2000 Elemente haben.

Weiterhin können die zur Verfügung stehenden Config-Items durch die Konfiguration der Verwendungsstatus eingeschränkt werden. So könnten z. B. in einem dynamischen Feld nur Config-Items der Klasse "Computer" zur Auswahl stehen, eingeschränkt auf die Verwendungsstatus "in Wartung" und "Produktiv".

Bei der Ausgabe des dynamischen Felds werden die Namen der gewählten Config-Items angezeigt.

__HINWEIS:__ Sollte durch Umkonfiguration der Verwendungsstatus in einem dynamischen Feld der jeweils im Objekt (Ticket, Artikel) gespeicherte Wert nicht mehr zur Verfügung stehen, so wird dieser für das Objekt bei der nächsten Bearbeitung auf leer gesetzt.

## Verlinkung
Config-Items können mit Tickets verlinkt werden. Sobald ein dynamisches Feld der beiden obigen Typen im Ticket-Kontext erzeugt wird, kann gewählt werden, welcher Linktyp verwendet werden soll. Außerdem kann die Linkrichtung bestimmt werden, also Config-Item zu Ticket oder umgekehrt.

Für jedes dynamische Feld der beiden obigen Typen kann bestimmt werden, ob die Links zwischen Ticket und Config-Item ebenfalls entfernt oder beibehalten werden sollen.

## Befüllung zusätzlicher dynamischer Felder
Im Konfigurationsdialog der beiden neuen dynamischen Config-Item-Feldtypen können zusätzliche dynamische Felder konfiguriert werden, die automatisch mit weiteren Daten des gewählten Config-Items befüllt werden. Falls beim Feldtyp Config-Item-Mehrfachauswahl bei der Eingabe der Ticketdaten mehrere Config-Items gewählt werden, werden deren Daten falls möglich je nach Typ des zusätzlichen dynamischen Felds, das befüllt werden soll, zusammengefasst.

Der jeweils zu setzende Wert aus dem Config-Item kann durch eine Kombination von Feldname(n) und optional Index referenziert werden. Beispiele:

1. Das Feld 'Name' ist ein einfaches Textfeld. In diesem Fall wird einfach 'Name' eingetragen.
2. Das Feld 'CPU' ist ein Textfeld. Es können jedoch mehrere CPUs im Config-Item hinterlegt werden. Trägt man in der Konfiguration 'CPU' ein, so werden je nach Typ des zusätzlich zu befüllenden dynamischen Felds alle eingetragenen CPUs per Komma getrennt zusammengefasst oder im Fall eines Multiselect-Felds entsprechend mehrere ausgewählt. Sollte die mehrfache Speicherung einer CPU im dynamischen Feld nicht möglich sein, so wird nur die erste CPU aus dem Config-Item verwendet.
3. Das Feld 'Netzwerkadapter' kann mehrfach befüllt werden. Außerdem können je Netzwerkadapter mehrere IP-Adressen hinterlegt werden. Soll z. B. in einem dynamischen Textfeld die dritte IP-Adresse des zweiten Netzwerkadapters hinterlegt werden, so wird dieser über 'NIC::2::IP::3' referenziert.

Die Befüllung der zusätzlichen dynamischen Felder kann entweder direkt im Frontend (also im Browser, vor der Speicherung/Aktualisierung des Tickets) oder im Backend (bei Speicherung/Aktualisierung des Tickets) erfolgen.

### Zu beachten
Es ist zu beachten, dass bei der Konfiguration der zu befüllenden dynamischen Felder keine Prüfung stattfindet, ob ein dynamisches Feld existiert oder ein gültiges Config-Item-Feld referenziert wurde. Solche Fehlkonfigurationen werden bei der Befüllung der dynamischen Felder ignoriert.

Außerdem steht die Befüllung zusätzlicher dynamischer Felder nur für den Objekttyp Ticket zur Verfügung. D. h., dass z. B. dynamische Felder, die für Artikel oder Kundenbenutzer konfiguriert wurden, nicht durch diese Funktion befüllt werden können. Des weiteren steht die Konfiguration zusätzlicher dynamischer Felder ebenfalls nur dann zur Verfügung, wenn das Config-Item-Auswahlfeld ebenfalls dem Objekttyp Ticket zugeordnet wurde.
