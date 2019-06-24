# Funktionalität

Dieses Paket ergänzt OTRS um dynamische Feldtypen für Config-Items.

Die folgenden Typen werden ergänzt:

- Config-Item-Einfachauswahl
- Config-Item-Mehrfachauswahl

In dynamischen Feldern dieser Typen stehen alle Config-Items zur Auswahl, die zur konfigurierten Klasse gehören. Dabei ist zu beachten, dass diese dynamischen Felder nur mit Config-Item-Klassen eingesetzt werden sollten, die weniger als 2000 Elemente haben.

Weiterhin können die zur Verfügung stehenden Config-Items durch die Konfiguration der Verwendungsstatus eingeschränkt werden. So könnten z. B. in einem dynamischen Feld nur Config-Items der Klasse "Computer" zur Auswahl stehen, eingeschränkt auf die Verwendungsstatus "in Wartung" und "Produktiv".

Bei der Ausgabe des dynamischen Felds werden die Namen der gewählten Config-Items angezeigt.

__HINWEIS:__ Sollte durch Umkonfiguration der Verwendungsstatus in einem dynamischen Feld der jeweils im Objekt (Ticket, Artikel) gespeicherte Wert nicht mehr zur Verfügung stehen, so wird dieser für das Objekt bei der nächsten Bearbeitung auf leer gesetzt.
