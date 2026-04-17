// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'La mia squadra';

  @override
  String get authWelcomeBack => 'Bentornato';

  @override
  String get authCreateAccount => 'Crea il tuo account';

  @override
  String get authHaveAccountLogin => 'Hai già un account? Registrazione';

  @override
  String get authNoAccountRegister => 'Nessun conto? Registro';

  @override
  String get loginEmailLabel => 'E-mail';

  @override
  String get loginEmailError => 'Inserisci la tua email';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginPasswordMinError => 'Almeno 6 caratteri';

  @override
  String get loginSubmit => 'Registrazione';

  @override
  String get loginForgotPassword => 'Ha dimenticato la password';

  @override
  String get registerFullNameLabel => 'Nome e cognome';

  @override
  String get registerNameError => 'Per favore inserisci il tuo nome';

  @override
  String get registerEmailInvalid => 'E-mail non valida';

  @override
  String get registerSubmit => 'Creare un account';

  @override
  String get authCheckEmailTitle => 'Controlla la tua email';

  @override
  String get authUnderstand => 'OK';

  @override
  String authRegisterEmailConfirm(String email) {
    return 'Abbiamo inviato un collegamento a $email. Aprilo per attivare il tuo account prima di accedere. Controlla anche la cartella spam.';
  }

  @override
  String get authRegisterEmailActive =>
      'Il tuo account è attivo. Controlla la tua casella di posta per verificare se è presente un\'e-mail di verifica o di benvenuto (incluso lo spam).';

  @override
  String get homeLogoutTooltip => 'disconnessione';

  @override
  String get homeInvitations => 'Inviti';

  @override
  String get homeNewTeam => 'Nuova squadra';

  @override
  String get homeLoadingTeams => 'Caricamento delle tue squadre…';

  @override
  String get homeRetry => 'Riprova';

  @override
  String get homeYourPanel => 'La tua dashboard';

  @override
  String get homeTeamCountOne => 'Hai 1 squadra. Tocca una carta per aprirla.';

  @override
  String homeTeamCountMany(int count) {
    return 'Hai $count squadre. Tocca una carta per aprirla.';
  }

  @override
  String get homeEmptyTitle => 'Non hai ancora nessuna squadra';

  @override
  String get homeEmptySubtitle =>
      'Crea la tua prima squadra con il pulsante mobile o controlla se hai inviti in sospeso.';

  @override
  String get homeEmptyHintNewTeam => 'Nuova squadra: dettagli base e stemma';

  @override
  String get homeEmptyHintInvitations => 'Inviti: unisciti a un team esistente';

  @override
  String get languageSpanish => 'Spagnolo (ES)';

  @override
  String get languageEnglish => 'Inglese (EN)';

  @override
  String get languageFrench => 'Francese (FR)';

  @override
  String get languageItalian => 'Italiano (IT)';

  @override
  String get languageSelectorTooltip => 'Lingua dell\'app';

  @override
  String get roleSuperAdmin => 'Super amministratore';

  @override
  String get roleAdmin => 'Ammin';

  @override
  String get rolePlayer => 'Giocatore';

  @override
  String get roleExternal => 'Esterno';

  @override
  String get roleSpectator => 'Spettatore';

  @override
  String get tableColumnPlayer => 'Giocatore';

  @override
  String get tableColumnAttends => 'Presente';

  @override
  String get tableColumnAbsent => 'Assente';

  @override
  String get convocationCallAll => 'Tutto';

  @override
  String get convocationPlayerStatus => 'Stato';

  @override
  String get convocationEmptyRoster => 'Nessun giocatore in rosa';

  @override
  String get convocationToggleHint =>
      'Chiama tutti contemporaneamente o tocca ciascun giocatore per attivare Sì/No.';

  @override
  String get commonYes => 'SÌ';

  @override
  String get commonNo => 'NO';

  @override
  String get accessInviteSend => 'Invia invito';

  @override
  String get accessInviteNeedAuth =>
      'Devi aver effettuato l\'accesso per inviare gli inviti';

  @override
  String get accessAdminOnlyInvite =>
      'Solo un amministratore del team può invitare o rimuovere l\'accesso.';

  @override
  String get accessUsersWithAccess => 'Utenti con accesso';

  @override
  String get accessListBlurb =>
      'Elenco live: si aggiorna quando qualcuno ottiene o perde l\'accesso. Ogni riga mostra nome ed email (profili) per identificare la persona.';

  @override
  String get accessPeopleCountSingle => '1 persona';

  @override
  String accessPeopleCountMany(int count) {
    return '$count persone';
  }

  @override
  String get accessEmptyMembersTitle => 'Nessun altro ha ancora accesso.';

  @override
  String get accessEmptyMembersHint =>
      'Invita via email con il pulsante qui sotto.';

  @override
  String get accessProfileNoName => 'Nessun nome sul profilo';

  @override
  String get accessProfileNoEmail =>
      'Email non disponibile (controlla il profilo nell\'app)';

  @override
  String get accessNamePrefix => 'Nome:';

  @override
  String get accessEmailPrefix => 'E-mail:';

  @override
  String get accessRolePrefix => 'Ruolo:';

  @override
  String get accessYou => 'Voi';

  @override
  String accessInviteSent(String email, String role) {
    return 'Invito inviato a $email come $role.';
  }

  @override
  String get navMenuTooltip => 'Menù di squadra';

  @override
  String get navMyTeams => 'Le mie squadre';

  @override
  String get navTeamHomeSubtitle => 'Squadra a casa';

  @override
  String get navAttendance => 'Partecipazione';

  @override
  String get navConvocation => 'Richiamata';

  @override
  String get navMatch => 'Incontro';

  @override
  String get navManagement => 'Gestione';

  @override
  String get actionCancel => 'Cancellare';

  @override
  String get actionConfirm => 'Confermare';

  @override
  String get screenAttendance => 'Partecipazione';

  @override
  String get screenConvocation => 'Richiamata';

  @override
  String get screenConvocationGenerated => 'Richiamo dell\'immagine';

  @override
  String get screenMatches => 'Partite';

  @override
  String get screenMatchLive => 'Partita dal vivo';

  @override
  String get screenMatchDetail => 'Dettagli della partita';

  @override
  String get screenDeleteMatch => 'Elimina corrispondenza';

  @override
  String get screenDeleteAttendance => 'Elimina le presenze';

  @override
  String get screenTeamManagement => 'Gestione della squadra';

  @override
  String get screenTeamAccess => 'Accesso alla squadra';

  @override
  String get screenRoster => 'Squadra';

  @override
  String get screenSelectLocation => 'Scegli la posizione';

  @override
  String get screenNewTeamPage => 'Nuova squadra';

  @override
  String get screenAddPlayer => 'Aggiungi giocatore';

  @override
  String get screenEditPlayer => 'Modifica giocatore';

  @override
  String get shareImageTooltip => 'Condividi l\'immagine';

  @override
  String convocationShareText(String teamName) {
    return 'Convocazione di $teamName';
  }

  @override
  String get backToTeam => 'Ritorno in squadra';

  @override
  String get dialogNoAccessTitle => 'Nessun accesso alla squadra';

  @override
  String get dialogNoAccessBody =>
      'Non hai più accesso a questa squadra. È stato rimosso dalla tua dashboard e non potrai reinserirlo finché un amministratore non ti inviterà nuovamente.';

  @override
  String get dialogLeaveTeamTitle => 'Lascia la squadra';

  @override
  String leaveTeamPromptExternal(String teamName) {
    return 'Lasciare $teamName? Non vedrai più la squadra o le partite finché un amministratore non ti inviterà nuovamente.';
  }

  @override
  String leaveTeamPromptAdmin(String teamName) {
    return 'Lasciare $teamName come amministratore? Perderai i permessi di gestione; potrai ritornare solo se un super amministratore ti invita nuovamente.';
  }

  @override
  String leaveTeamPromptPlayer(String teamName) {
    return 'Lasciare $teamName come giocatore? Verrai rimosso dalla squadra finché non sarai nuovamente registrato.';
  }

  @override
  String leaveTeamPromptGeneric(String teamName) {
    return 'Lasciare $teamName?';
  }

  @override
  String get leaveTeamButton => 'Lascia la squadra';

  @override
  String get snackbarLeftTeam => 'Hai lasciato la squadra';

  @override
  String get teamCheckingAccess => 'Verifica dell\'accesso…';

  @override
  String get teamLoadingRoster => 'Caricamento squadra…';

  @override
  String get teamEmptyRosterTitle => 'Nessun giocatore in squadra ancora';

  @override
  String get teamEmptyRosterHint =>
      'Aggiungili da Gestione → Modifica squadra.';

  @override
  String get teamHeaderLeaveShort => 'Partire';

  @override
  String get teamPlayerCountOne => '1 giocatore';

  @override
  String teamPlayerCountMany(int count) {
    return '$count giocatori';
  }

  @override
  String get teamMustLoginAddPlayers =>
      'Devi essere registrato per aggiungere giocatori';

  @override
  String get teamMustLoginEditPlayers =>
      'Devi essere registrato per modificare i giocatori';

  @override
  String get teamMustLoginDeletePlayers =>
      'Devi aver effettuato l\'accesso per eliminare i giocatori';

  @override
  String get dialogDeletePlayerLead => 'Sei sicuro di voler eliminare?';

  @override
  String get teamManagementLogoLabel => 'Distintivo';

  @override
  String get teamManagementLogoTapHint => 'Tocca per modificare';

  @override
  String get teamManagementNameLabel => 'Nome della squadra';

  @override
  String get teamManagementNameHint => 'per esempio. FC Riverside';

  @override
  String get accessDefaultUserName => 'Utente';

  @override
  String get teamMgmtSectionTeamData => 'Dettagli della squadra';

  @override
  String get teamMgmtColorRowLabel => 'Colore della squadra';

  @override
  String get teamMgmtColorPickTooltip => 'Tocca per scegliere un colore';

  @override
  String get teamMustLoginSaveChanges =>
      'Devi aver effettuato l\'accesso per salvare le modifiche';

  @override
  String teamMgmtLogoUploadError(String message) {
    return 'Impossibile caricare il badge: $message';
  }

  @override
  String get teamMgmtSaveSuccess => 'Modifiche salvate';

  @override
  String get teamMgmtSectionRosterAccess => 'Squadra e accesso';

  @override
  String get teamMgmtEditRosterTitle => 'Modifica squadra';

  @override
  String get teamMgmtEditRosterSubtitle =>
      'Aggiungi, rimuovi e modifica giocatori';

  @override
  String get teamMgmtAccessTitle => 'Gestisci l\'accesso';

  @override
  String get teamMgmtAccessSubtitle =>
      'Invita amministratori o spettatori nella squadra';

  @override
  String get teamMgmtSectionMaintenance => 'Manutenzione dei dati';

  @override
  String get teamMgmtDeleteMatchesTitle => 'Elimina corrispondenze';

  @override
  String get teamMgmtDeleteMatchesSubtitle =>
      'Rimuovi partite specifiche dal programma';

  @override
  String get teamMgmtDeleteAttendanceTitle => 'Elimina le presenze';

  @override
  String get teamMgmtDeleteAttendanceSubtitle =>
      'Rimuovere i giorni di rilevamento delle presenze';

  @override
  String get teamMgmtSectionCritical => 'Zona pericolosa';

  @override
  String get teamAccessLoadMembersError =>
      'Impossibile caricare i membri del team';

  @override
  String get convSectionMatch => 'Incontro';

  @override
  String get convRivalLabel => 'Avversario';

  @override
  String get convVenueLabel => 'Luogo';

  @override
  String get convHome => 'Casa';

  @override
  String get convAway => 'Lontano';

  @override
  String get convLocationHint => 'Luogo (facoltativo)';

  @override
  String get convLocationFieldHint =>
      'Luogo o indirizzo · mostrato nell\'immagine';

  @override
  String get matchFormation => 'Formazione';

  @override
  String get matchDeleteEvent => 'Elimina evento';

  @override
  String get matchConfirmAction => 'Conferma l\'azione';

  @override
  String get matchPickAssistant => 'Seleziona assistente';

  @override
  String get matchNoAttendanceOption => 'Nessuna presenza';

  @override
  String get matchEndGame => 'Fine della partita';

  @override
  String get matchMustLoginStart =>
      'Devi essere loggato per iniziare la partita';

  @override
  String get matchStartedOk => 'La partita è iniziata con successo';

  @override
  String get matchMustLoginPause =>
      'Devi aver effettuato l\'accesso per mettere in pausa la partita';

  @override
  String get matchStateUpdateFail =>
      'Impossibile aggiornare lo stato della corrispondenza';

  @override
  String get matchMustLoginResume =>
      'Devi essere loggato per riprendere la partita';

  @override
  String get matchMustLoginFinish =>
      'Devi essere loggato per terminare la partita';

  @override
  String get matchOpponentGoal => 'Gol avversario';

  @override
  String get matchSubtractOur => '− Noi';

  @override
  String get matchSubtractRival => '− Loro';

  @override
  String get matchDeleteEventQuestion =>
      'Eliminare questo evento della partita? Punteggio, note e disciplina verranno ricalcolati.';

  @override
  String get matchEventDeleted => 'Evento eliminato';

  @override
  String get matchEventDeleteFail => 'Impossibile eliminare l\'evento';

  @override
  String get matchLoginRequiredShort => 'Devi essere registrato';

  @override
  String get matchActionRegisterLogin =>
      'Devi essere loggato per registrare le azioni';

  @override
  String get matchActionRegisterFail => 'Impossibile salvare l\'azione';

  @override
  String get matchActionRegisteredPrefix => 'Azione salvata per';

  @override
  String get matchEndGameConfirm =>
      'Terminare la partita? Il risultato finale verrà salvato.';

  @override
  String matchRegisterActionIntro(String label) {
    return 'Sei sicuro di voler registrare \"$label\" per';
  }

  @override
  String get dialogDeletePlayerTitle => 'Elimina giocatore';

  @override
  String get dialogDeleteTeamTitle => 'Elimina squadra';

  @override
  String get dialogRevokeAccessTitle => 'Rimuovere l\'accesso';

  @override
  String get dialogInviteUserTitle => 'Invita utente';

  @override
  String get accessRevokeBody => 'Rimuovere l\'accesso di questo utente?';

  @override
  String get accessRevokeAction => 'Rimuovere';

  @override
  String get accessRevokedOk => 'Accesso rimosso con successo';

  @override
  String get accessRevokeFail => 'Impossibile rimuovere l\'accesso';

  @override
  String get accessCannotRemoveSuperAdmin =>
      'Solo il creatore del team (super amministratore) può rimuovere un altro super amministratore.';

  @override
  String get accessInviteRole => 'Ruolo';

  @override
  String get accessAdminOnlyRevoke =>
      'Solo un amministratore del team può rimuovere l\'accesso.';

  @override
  String get teamColorDefault => 'Predefinito (app verde)';

  @override
  String get teamColorSheetTitle => 'Colore della squadra';

  @override
  String get teamColorSheetHint =>
      'Barra superiore, pulsanti e accenti all\'interno dell\'area della squadra. Le carte e le aree morbide utilizzano la tua tinta (stessa sottigliezza del verde dell\'app). Vuoto = verde predefinito.';

  @override
  String get teamSaveDataButton => 'Salva i dettagli della squadra';

  @override
  String get actionDelete => 'Eliminare';

  @override
  String get actionRemove => 'Rimuovere';

  @override
  String get teamDeletedSnackbar => 'Team eliminato con successo';

  @override
  String get matchDeleteNeedLogin =>
      'Devi aver effettuato l\'accesso per eliminare le corrispondenze';

  @override
  String matchDeleteConfirmBody(String opponent) {
    return 'Eliminare la partita contro $opponent?';
  }

  @override
  String get matchListLoadError => 'Impossibile caricare le corrispondenze';

  @override
  String get matchStatsLoadError => 'Impossibile caricare i dati della partita';

  @override
  String get matchListEmpty => 'Nessuna partita per questa squadra';

  @override
  String get matchStatusPending => 'Programmato';

  @override
  String get matchStatusFirstHalf => '1a metà';

  @override
  String get matchStatusHalfTime => 'A metà tempo';

  @override
  String get matchStatusSecondHalf => '2a metà';

  @override
  String get matchStatusFinished => 'Finito';

  @override
  String get matchLastEvent => 'Ultimo evento';

  @override
  String get matchScoreAndTime => 'Punteggio e tempo';

  @override
  String get matchQuickScore => 'Punteggio veloce';

  @override
  String get matchGoalsFromFieldHint =>
      'I gol vengono registrati dal campo (giocatore) o dalle azioni.';

  @override
  String get matchFieldAndFormation => 'Passo e formazione';

  @override
  String get matchSquadTitle => 'Squadra';

  @override
  String get matchSquadHintSpectator =>
      'Modalità spettatore: elenco e presentazione sono di sola visualizzazione.';

  @override
  String get matchSquadHintCoach =>
      'Tocca un giocatore per selezionarlo; tocca il campo per allinearti o aprire azioni.';

  @override
  String get matchPlayerSentOffCannotReturn =>
      'Il giocatore espulso non può rientrare';

  @override
  String get matchEventsTitle => 'Eventi della partita';

  @override
  String get matchEventsHintSpectator => 'Cronologia della partita.';

  @override
  String get matchEventsHintCoach =>
      'Tocca un evento per eliminarlo. Solo gli amministratori del team possono rimuovere eventi.';

  @override
  String get matchEventsEmpty => 'Nessun evento ancora registrato';

  @override
  String get matchStartGameButton => 'Inizia la partita';

  @override
  String get matchResumeGameButton => 'Riprendi la partita';

  @override
  String get matchHalfTimeButton => 'A metà tempo';

  @override
  String get matchPhaseNotStarted => 'Non iniziato';

  @override
  String get matchSpectatorNoPlayerActions =>
      'Modalità spettatore: non è possibile registrare le azioni dei giocatori';

  @override
  String get matchConfirmGoalTitle => 'Conferma obiettivo';

  @override
  String get matchConfirmAddGoalOur =>
      'Aggiungere un obiettivo per la tua squadra?';

  @override
  String get matchConfirmAddGoalRival =>
      'Aggiungere un goal per l\'avversario?';

  @override
  String get matchMustLoginRegisterGoals =>
      'Devi aver effettuato l\'accesso per accedere agli obiettivi';

  @override
  String get matchGoalsOurTeamFromField =>
      'I gol della tua squadra vengono registrati da un giocatore in campo';

  @override
  String get matchOpponentGoalRegisteredOk => 'Gol avversario parato';

  @override
  String get matchGoalSaveFail => 'Impossibile salvare il gol';

  @override
  String get matchRemoveGoalTitle => 'Rimuovi obiettivo';

  @override
  String get matchConfirmRemoveGoalOur =>
      'Rimuovere un goal dalla tua squadra?';

  @override
  String get matchConfirmRemoveGoalRival => 'Togliere un gol all\'avversario?';

  @override
  String get matchMustLoginRemoveGoals =>
      'Devi aver effettuato l\'accesso per rimuovere gli obiettivi';

  @override
  String get matchNoGoalsToRemove => 'Nessun obiettivo da rimuovere';

  @override
  String get matchGoalNotFoundInDb => 'Obiettivo non trovato nel database';

  @override
  String get matchGoalRemovedOk => 'Obiettivo rimosso';

  @override
  String get matchGoalRemoveFail => 'Impossibile rimuovere l\'obiettivo';

  @override
  String get matchConvocationLoadError =>
      'Impossibile caricare l\'elenco delle squadre';

  @override
  String get matchFillAllPositionsBeforeStart =>
      'Posiziona tutti i giocatori prima di iniziare la partita';

  @override
  String get matchConfirmStartTitle => 'Inizia la partita';

  @override
  String get matchConfirmStartBody => 'Iniziare la partita?';

  @override
  String get matchConfirmHalfTimeTitle => 'Vai all\'intervallo';

  @override
  String get matchConfirmHalfTimeBody => 'Passare all\'intervallo?';

  @override
  String get matchConfirmResumeTitle => 'Riprendi la partita';

  @override
  String get matchConfirmResumeBody => 'Inizia il secondo tempo?';

  @override
  String get matchEndGameDialogBody =>
      'Terminare la partita? Le statistiche verranno salvate.';

  @override
  String get matchEndGameAction => 'FINE';

  @override
  String get matchSentOffDoubleYellow => 'espulso (secondo giallo)';

  @override
  String get matchSentOffSimple => 'mandato via';

  @override
  String matchUnknownPlayerId(int id) {
    return 'Giocatore $id';
  }

  @override
  String get matchLiveFormationRegistered => 'Formazione salvata';

  @override
  String matchLiveFormationLine(String formation) {
    return 'Formazione: $formation';
  }

  @override
  String get matchLiveSubstitutionEnters => 'Sostituzione · On';

  @override
  String get matchLiveSubstitutionLeaves => '· Spento';

  @override
  String get matchLivePeriodFallback => 'Modifica del periodo o dello stato';

  @override
  String get matchLiveGoalBy => 'Gol di';

  @override
  String get matchLiveAssistOpening => '(assist';

  @override
  String get matchLiveAssistClosing => ')';

  @override
  String get matchLiveConcededDefault => 'Gol concesso';

  @override
  String get matchLiveOwnGoal => 'Autogol ·';

  @override
  String get matchLiveYellowCard => 'Cartellino giallo:';

  @override
  String get matchLiveRedCard => 'Cartellino rosso:';

  @override
  String get matchLiveSaveBy => 'Risparmia entro';

  @override
  String matchLiveSaveWithNote(String note) {
    return 'Salva · $note';
  }

  @override
  String get matchLiveSaveOnly => 'Salva';

  @override
  String get matchLiveKeyPass => 'Passaggio chiave:';

  @override
  String get matchLiveGoodPass => 'Buon passaggio:';

  @override
  String get matchLiveBadPass => 'Passaggio scadente:';

  @override
  String get matchLiveGoodPlay => 'Bel gioco:';

  @override
  String get matchLiveBadPlay => 'Gioco scadente:';

  @override
  String get matchLiveBallRecovery => 'Palla vinta:';

  @override
  String get matchLiveEvent => 'Evento';

  @override
  String matchLiveEventLine(String label, String note) {
    return '$label: $note';
  }

  @override
  String get matchNoteFirstHalfStart => 'Calcio d\'inizio del primo tempo';

  @override
  String get matchNoteSecondHalfStart => 'Calcio d\'inizio del secondo tempo';

  @override
  String get matchNoteMatchFinished => 'A tempo pieno';

  @override
  String get matchActionLabelGoal => 'Obiettivo';

  @override
  String get matchActionLabelGoodPass => 'Buon passaggio';

  @override
  String get matchActionLabelGoodPlay => 'Buon gioco';

  @override
  String get matchActionLabelBallRecovery => 'Recupero palla';

  @override
  String get matchActionLabelYellowCard => 'Cartellino giallo';

  @override
  String get matchActionLabelRedCard => 'Cartellino rosso';

  @override
  String get matchActionLabelBadPass => 'Passaggio scadente';

  @override
  String get matchActionLabelBadPlay => 'Gioco scadente';

  @override
  String get matchActionLabelKeyPass => 'Passaggio chiave';

  @override
  String get matchGoalRegisteredPrefix => 'Gol salvato per';

  @override
  String get attendanceSaveHint =>
      'Tocca ✓ per presente o X per assente, quindi salva per il giorno selezionato.';

  @override
  String get attendanceSaveButton => 'Risparmia presenze';

  @override
  String get attendanceSaveNeedLogin =>
      'Devi essere registrato per salvare le presenze';

  @override
  String get attendanceSaveTeamLoadError =>
      'Impossibile caricare la rosa della squadra';

  @override
  String get attendanceSaveInProgress => 'Risparmio…';

  @override
  String get attendanceSaveSuccess => 'Partecipazione salvata correttamente';

  @override
  String get convDatetimeSectionTitle => 'Data e orari';

  @override
  String get convPickDateTooltip => 'Scegli la data';

  @override
  String get tooltipChange => 'Modifica';

  @override
  String get attendanceDeleteLoadError =>
      'Impossibile caricare i giorni di presenza';

  @override
  String get attendanceDeleteEmpty => 'Nessun giorno di formazione registrato';

  @override
  String get attendanceDeleteNeedLogin =>
      'Devi aver effettuato l\'accesso per eliminare la partecipazione';

  @override
  String get teamDeleteNavTitle => 'Elimina squadra';

  @override
  String get teamDeleteNavSubtitle => 'Togli la mazza e nascondila da casa';

  @override
  String get teamDeleteNeedLogin =>
      'Devi aver effettuato l\'accesso per eliminare la squadra';

  @override
  String get teamDeleteConfirmBody =>
      'Eliminare questa squadra? Questa operazione non può essere annullata.';

  @override
  String attendanceDeleteConfirmBody(String date) {
    return 'Eliminare la partecipazione per $date?';
  }

  @override
  String get dialogClose => 'Vicino';

  @override
  String get convocationNotesTitle => 'Note';

  @override
  String get convocationNotesHint => 'Kit, puntualità, messaggio alla squadra…';

  @override
  String get convocationSavedSuccess => 'Chiamata salvata con successo';

  @override
  String get convocationImageSectionMatchDetails => 'Dati della partita';

  @override
  String get convocationImageLabelTeam => 'Squadra';

  @override
  String get convocationImageLabelFixture => 'Partita';

  @override
  String get convocationImageLabelCallDateTime => 'Data e ora di convocazione';

  @override
  String get convocationImageLabelMeetingVenue => 'Luogo della convocazione';

  @override
  String get convocationImageLabelMatchVenue => 'Luogo della partita';

  @override
  String get convocationImageVenueHomeInstallations => 'Strutture del club';

  @override
  String get convocationImageLabelDate => 'Data';

  @override
  String get convocationImageLabelMatchTime => 'Orario d\'inizio';

  @override
  String get convocationImageLabelCallTime => 'Ora dell\'incontro';

  @override
  String get convocationImageLabelVenue => 'Luogo';

  @override
  String get convocationImageSectionSquad => 'Giocatori convocati';

  @override
  String get convocationImageObservationsTitle => 'Note';

  @override
  String get convocationImagePlayerFallback => 'Giocatore';

  @override
  String get convocationImageSectionMatchDetailsSubtitle =>
      'Data, orari e luogo — leggi con calma';

  @override
  String get convocationImageLabelMatchKickoff =>
      'ORARIO DI INIZIO (INIZIO PARTITA)';

  @override
  String get convocationImageLabelCallArrival =>
      'ORARIO DI CONVOCAZIONA (ARRIVO)';

  @override
  String get convocationImageCallTimeReminder =>
      'Importante: arriva prima di quest\'ora, non all\'inizio della partita.';

  @override
  String get convocationImageMapLinkIntro =>
      'Dal telefono puoi aprire questo link per vedere il luogo sulla mappa:';

  @override
  String get convocationImagePlaceHomeHeadline => 'PARTITA IN CASA';

  @override
  String get convocationImagePlaceHomeDetail => 'Giochiamo in casa nostra.';

  @override
  String get convocationImagePlaceAwayHeadline => 'PARTITA IN TRASFERTA';

  @override
  String get convocationImagePlaceAwayNoAddressDetail =>
      'Il club confermerà l\'indirizzo esatto. Chiedi all\'allenatore.';

  @override
  String matchSummaryVs(String opponent) {
    return 'contro $opponent';
  }

  @override
  String get matchVenueHome => 'Casa';

  @override
  String get matchVenueAway => 'Lontano';

  @override
  String get matchScoreForLabel => 'Per';

  @override
  String get matchScoreAgainstLabel => 'Contro';

  @override
  String get matchStatsScoreFinal => 'Punteggio finale';

  @override
  String get matchStatsScoreLive => 'Punto';

  @override
  String get matchStatsLoadingSummary => 'Caricamento riepilogo partita…';

  @override
  String get matchStatsSectionField => 'Tiro finale';

  @override
  String matchStatsFormationChip(String formation) {
    return 'Formazione: $formation';
  }

  @override
  String get matchStatsFieldDispositionHint =>
      'Layout basato sulle posizioni salvate al termine della partita.';

  @override
  String get matchStatsSectionTimeline => 'Cronologia';

  @override
  String get matchStatsTimelineEmpty => 'Nessun evento registrato';

  @override
  String get matchStatsTimelineEmptyHint =>
      'Gol, abbonamenti e cartellini appariranno qui una volta effettuato l\'accesso alla partita.';

  @override
  String get matchStatsMinutesPlayed => 'Minuti giocati';

  @override
  String get matchStatsStatGoals => 'Obiettivi';

  @override
  String get matchStatsStatAssists => 'Assist';

  @override
  String get matchStatsStatGoodPasses => 'Buoni passaggi';

  @override
  String get matchStatsStatBadPasses => 'Passaggi scadenti';

  @override
  String get matchStatsStatGoodPlays => 'Buone giocate';

  @override
  String get matchStatsStatBadPlays => 'Commedie scadenti';

  @override
  String get matchStatsOurGoalChip => 'Obiettivo per';

  @override
  String get matchStatsOwnGoalChip => 'Autogol';

  @override
  String get matchListLoading => 'Caricamento corrispondenze…';

  @override
  String get matchListEmptyStateTitle => 'Nessuna corrispondenza ancora';

  @override
  String get matchListEmptyStateBody =>
      'Le partite create da una chiamata verranno visualizzate qui. Tirare verso il basso per rinfrescare.';

  @override
  String get matchListCalendarTitle => 'Calendario';

  @override
  String matchListElapsedTime(String time) {
    return 'Ora: $time';
  }

  @override
  String get matchListHintLineupStart =>
      'Tocca per metterti in fila e iniziare';

  @override
  String get matchListHintManageResume => 'Tocca per gestire o riprendere';

  @override
  String get matchListHintViewStats => 'Tocca per visualizzare le statistiche';

  @override
  String get matchLineupSquadTitle => 'Squadra della partita';

  @override
  String get matchLineupStarters => 'Antipasti';

  @override
  String get matchLineupSubstitutes => 'Sostituti';

  @override
  String get matchLineupStarterTag => 'Antipasto';

  @override
  String get matchLineupSubstituteTag => 'Sostituire';

  @override
  String get matchFieldSelectPlayerFirst =>
      'Seleziona prima un giocatore nell\'elenco';

  @override
  String get matchFieldMaxPlayersExpulsionRule =>
      'Non si possono avere più giocatori in campo. Ogni giocatore espulso deve lasciare uno spazio libero.';

  @override
  String get matchConvocationTableEmpty =>
      'Nessun giocatore convocato per questa partita';

  @override
  String get matchDeletedSuccess => 'Corrispondenza eliminata correttamente';

  @override
  String get matchEventLegacyActionRegistered => 'Azione registrata';
}
