# DELTARUNE Internal Mod Menu 1.2.0 — solo mod

Questo pacchetto contiene esclusivamente sorgenti della mod e script di installazione. Non contiene data.win, traduzioni, dialoghi esportati, musica, sprite o programmi di terzi. Supporta gli adattatori dei capitoli 1–5 presenti nell'installazione.

## Installazione

1. Chiudi il gioco ed estrai tutto lo ZIP della mod.
2. Scarica ed estrai UTMT_CLI_v0.9.2.0-Windows.zip dalla release ufficiale: https://github.com/UnderminersTeam/UndertaleModTool/releases/tag/0.9.2.0 . Mantieni insieme tutti i file del programma.
3. Se hai già il vecchio mod menu, ripristina prima il suo backup originale. Installa la traduzione desiderata PRIMA della mod.
4. Avvia Install.cmd. Inserisci la cartella principale contenente DELTARUNE.exe e poi il percorso completo di UndertaleModCli.exe, senza virgolette esterne.
5. Attendi il messaggio di completamento, avvia il gioco normalmente e premi F1.

Servono Windows PowerShell 5.1, accesso in scrittura alla cartella del gioco e spazio per backup e archivi ricompilati. Installazione manuale tramite script: non è un pacchetto da trascinare in Vortex. Non interrompere la sostituzione degli archivi.

L'installer modifica il data.win dell'utente e genera i cataloghi dai suoi asset. Verifica dopo la scrittura che la tabella originale delle stringhe sia preservata. Non modifica file di lingua esterni o salvataggi. L'interfaccia del menu è in inglese; la lingua del gioco resta quella già installata. Traduzioni e aggiornamenti che cambiano il codice possono risultare incompatibili: se manca un punto obbligatorio di inserimento, la preparazione si interrompe prima dell'installazione.

## Uso

F1 apre/chiude; frecce per navigare e modificare; Invio seleziona; Esc torna indietro; Pagina su/giù scorre le liste; S cerca nei cataloghi. Nei campi numerici si può digitare.

Include TP, invincibilità, colpi letali, graze, velocità, incontri, inventario, denaro, consumabili infiniti, party, noclip, stanze, flag, musica, sprite/tinte, testo ed eventi finti. Sono disponibili soltanto gli asset realmente presenti nel capitolo; Noelle non è disponibile nel capitolo 1. Warp, boss, flag e party insoliti sono sperimentali e possono dipendere dallo stato della storia. Conserva una copia dei salvataggi prima di usarli: salvare nel gioco può rendere persistenti le modifiche a inventario e storia. Le schermate di corruzione finta sono effetti visivi. Le opzioni del menu si azzerano al riavvio.

## Rimozione

Chiudi il gioco, avvia Uninstall.cmd e indica la stessa cartella principale. Ripristina l'archivio esatto precedente all'installazione, verificandone l'hash. Conserva chapterN_windows/.internal-menu-release: contiene backup, stato e log. La rimozione non annulla le modifiche salvate durante il gioco.

Se data.win è cambiato dopo l'installazione, per esempio per un aggiornamento o un'altra mod, la rimozione si ferma senza sovrascriverlo. Non forzare backup vecchi su versioni nuove. Una traduzione installata successivamente che sostituisce data.win rimuove anche il menu.

I controlli di compilazione, conservazione dei testi e ripristino riguardano le cinque build locali usate per questa release; non equivalgono a un collaudo di tutte le lingue/versioni. Dettagli e comandi avanzati in README_EN.md. Mod non ufficiale. UndertaleModTool è un requisito esterno e mantiene la propria licenza.
