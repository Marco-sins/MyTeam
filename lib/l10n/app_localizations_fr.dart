// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Mon équipe';

  @override
  String get authWelcomeBack => 'Content de te revoir';

  @override
  String get authCreateAccount => 'Créez votre compte';

  @override
  String get authHaveAccountLogin => 'Vous avez déjà un compte ? Se connecter';

  @override
  String get authNoAccountRegister => 'Pas de compte ? Registre';

  @override
  String get loginEmailLabel => 'E-mail';

  @override
  String get loginEmailError => 'Entrez votre email';

  @override
  String get loginPasswordLabel => 'Mot de passe';

  @override
  String get loginPasswordMinError => 'Au moins 6 caractères';

  @override
  String get loginSubmit => 'Se connecter';

  @override
  String get loginForgotPassword => 'Mot de passe oublié';

  @override
  String get registerFullNameLabel => 'Nom et prénom';

  @override
  String get registerNameError => 'Veuillez entrer votre nom';

  @override
  String get registerEmailInvalid => 'E-mail invalide';

  @override
  String get registerSubmit => 'Créer un compte';

  @override
  String get authCheckEmailTitle => 'Vérifiez votre courrier électronique';

  @override
  String get authUnderstand => 'D\'ACCORD';

  @override
  String authRegisterEmailConfirm(String email) {
    return 'Nous avons envoyé un lien à $email. Ouvrez-le pour activer votre compte avant de vous connecter. Vérifiez également votre dossier spam.';
  }

  @override
  String get authRegisterEmailActive =>
      'Votre compte est actif. Vérifiez votre boîte de réception pour un e-mail de vérification ou de bienvenue (y compris le spam).';

  @override
  String get homeLogoutTooltip => 'se déconnecter';

  @override
  String get homeInvitations => 'Invitations';

  @override
  String get homeNewTeam => 'Nouvelle équipe';

  @override
  String get homeLoadingTeams => 'Chargement de vos équipes…';

  @override
  String get homeRetry => 'Réessayer';

  @override
  String get homeYourPanel => 'Votre tableau de bord';

  @override
  String get homeTeamCountOne =>
      'Vous avez 1 équipe. Appuyez sur une carte pour l\'ouvrir.';

  @override
  String homeTeamCountMany(int count) {
    return 'Vous avez $count équipes. Appuyez sur une carte pour l\'ouvrir.';
  }

  @override
  String get homeEmptyTitle => 'Vous n\'avez pas encore d\'équipes';

  @override
  String get homeEmptySubtitle =>
      'Créez votre première équipe avec le bouton flottant ou vérifiez si vous avez des invitations en attente.';

  @override
  String get homeEmptyHintNewTeam =>
      'Nouvelle équipe : détails de base et badge';

  @override
  String get homeEmptyHintInvitations =>
      'Invitations : rejoignez une équipe existante';

  @override
  String get languageSpanish => 'Espagnol (ES)';

  @override
  String get languageEnglish => 'Anglais (EN)';

  @override
  String get languageFrench => 'Français (FR)';

  @override
  String get languageItalian => 'Italien (IT)';

  @override
  String get languageSelectorTooltip => 'Langue de l\'application';

  @override
  String get roleSuperAdmin => 'Super administrateur';

  @override
  String get roleAdmin => 'Administrateur';

  @override
  String get rolePlayer => 'Joueur';

  @override
  String get roleExternal => 'Externe';

  @override
  String get roleSpectator => 'Spectateur';

  @override
  String get tableColumnPlayer => 'Joueur';

  @override
  String get tableColumnAttends => 'Présent';

  @override
  String get tableColumnAbsent => 'Absent';

  @override
  String get convocationCallAll => 'Tous';

  @override
  String get convocationPlayerStatus => 'Statut';

  @override
  String get convocationEmptyRoster => 'Aucun joueur dans l\'équipe';

  @override
  String get convocationToggleHint =>
      'Appelez tout le monde en même temps ou appuyez sur chaque joueur pour basculer Oui/Non.';

  @override
  String get commonYes => 'Oui';

  @override
  String get commonNo => 'Non';

  @override
  String get accessInviteSend => 'Envoyer une invitation';

  @override
  String get accessInviteNeedAuth =>
      'Vous devez être connecté pour envoyer des invitations';

  @override
  String get accessAdminOnlyInvite =>
      'Seul un administrateur d\'équipe peut inviter ou supprimer l\'accès.';

  @override
  String get accessUsersWithAccess => 'Utilisateurs ayant accès';

  @override
  String get accessListBlurb =>
      'Liste en direct : mise à jour lorsqu\'une personne obtient ou perd l\'accès. Chaque ligne affiche le nom et l\'adresse e-mail (profils) pour identifier la personne.';

  @override
  String get accessPeopleCountSingle => '1 personne';

  @override
  String accessPeopleCountMany(int count) {
    return '$count personnes';
  }

  @override
  String get accessEmptyMembersTitle =>
      'Personne d\'autre n\'y a encore accès.';

  @override
  String get accessEmptyMembersHint =>
      'Invitez par email avec le bouton ci-dessous.';

  @override
  String get accessProfileNoName => 'Aucun nom sur le profil';

  @override
  String get accessProfileNoEmail =>
      'E-mail indisponible (vérifiez le profil dans l\'application)';

  @override
  String get accessNamePrefix => 'Nom:';

  @override
  String get accessEmailPrefix => 'E-mail:';

  @override
  String get accessRolePrefix => 'Rôle:';

  @override
  String get accessYou => 'Toi';

  @override
  String accessInviteSent(String email, String role) {
    return 'Invitation envoyée à $email en tant que $role.';
  }

  @override
  String get navMenuTooltip => 'Menu d\'équipe';

  @override
  String get navMyTeams => 'Mes équipes';

  @override
  String get navTeamHomeSubtitle => 'Accueil de l\'équipe';

  @override
  String get navAttendance => 'Présence';

  @override
  String get navConvocation => 'Appel';

  @override
  String get navMatch => 'Correspondre';

  @override
  String get navManagement => 'Gestion';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionConfirm => 'Confirmer';

  @override
  String get screenAttendance => 'Présence';

  @override
  String get screenConvocation => 'Appel';

  @override
  String get screenConvocationGenerated => 'Image d\'appel';

  @override
  String get screenMatches => 'Matchs';

  @override
  String get screenMatchLive => 'Match en direct';

  @override
  String get screenMatchDetail => 'Détails du match';

  @override
  String get screenDeleteMatch => 'Supprimer la correspondance';

  @override
  String get screenDeleteAttendance => 'Supprimer la participation';

  @override
  String get screenTeamManagement => 'Gestion d\'équipe';

  @override
  String get screenTeamAccess => 'Accès équipe';

  @override
  String get screenRoster => 'Équipe';

  @override
  String get screenSelectLocation => 'Choisir un emplacement';

  @override
  String get screenNewTeamPage => 'Nouvelle équipe';

  @override
  String get screenAddPlayer => 'Ajouter un joueur';

  @override
  String get screenEditPlayer => 'Modifier le joueur';

  @override
  String get shareImageTooltip => 'Partager l\'image';

  @override
  String convocationShareText(String teamName) {
    return 'Appel de $teamName';
  }

  @override
  String get backToTeam => 'Retour à l\'équipe';

  @override
  String get dialogNoAccessTitle => 'Pas d\'accès en équipe';

  @override
  String get dialogNoAccessBody =>
      'Vous n\'avez plus accès à cette équipe. Il a été supprimé de votre tableau de bord et vous ne pouvez pas y accéder à nouveau jusqu\'à ce qu\'un administrateur vous invite à nouveau.';

  @override
  String get dialogLeaveTeamTitle => 'Quitter l\'équipe';

  @override
  String leaveTeamPromptExternal(String teamName) {
    return 'Quitter $teamName ? Vous ne verrez plus l\'équipe ou les matchs jusqu\'à ce qu\'un administrateur vous invite à nouveau.';
  }

  @override
  String leaveTeamPromptAdmin(String teamName) {
    return 'Laisser $teamName en tant qu\'administrateur ? Vous perdrez les autorisations de gestion ; vous ne pouvez revenir que si un super administrateur vous invite à nouveau.';
  }

  @override
  String leaveTeamPromptPlayer(String teamName) {
    return 'Laisser $teamName en tant que joueur ? Vous serez retiré de l\'équipe jusqu\'à ce que vous soyez à nouveau inscrit.';
  }

  @override
  String leaveTeamPromptGeneric(String teamName) {
    return 'Quitter $teamName ?';
  }

  @override
  String get leaveTeamButton => 'Quitter l\'équipe';

  @override
  String get snackbarLeftTeam => 'Tu as quitté l\'équipe';

  @override
  String get teamCheckingAccess => 'Vérification de l\'accès…';

  @override
  String get teamLoadingRoster => 'Chargement de l’équipe…';

  @override
  String get teamEmptyRosterTitle =>
      'Aucun joueur dans l\'équipe pour l\'instant';

  @override
  String get teamEmptyRosterHint =>
      'Ajoutez-les depuis Gestion → Modifier l\'équipe.';

  @override
  String get teamHeaderLeaveShort => 'Partir';

  @override
  String get teamPlayerCountOne => '1 joueur';

  @override
  String teamPlayerCountMany(int count) {
    return '$count joueurs';
  }

  @override
  String get teamMustLoginAddPlayers =>
      'Vous devez être connecté pour ajouter des joueurs';

  @override
  String get teamMustLoginEditPlayers =>
      'Vous devez être connecté pour modifier les joueurs';

  @override
  String get teamMustLoginDeletePlayers =>
      'Vous devez être connecté pour supprimer des joueurs';

  @override
  String get dialogDeletePlayerLead => 'Etes-vous sûr de vouloir supprimer';

  @override
  String get teamManagementLogoLabel => 'Badge';

  @override
  String get teamManagementLogoTapHint => 'Appuyez pour modifier';

  @override
  String get teamManagementNameLabel => 'Nom de l\'équipe';

  @override
  String get teamManagementNameHint => 'par ex. FC Riverside';

  @override
  String get accessDefaultUserName => 'Utilisateur';

  @override
  String get teamMgmtSectionTeamData => 'Détails de l\'équipe';

  @override
  String get teamMgmtColorRowLabel => 'Couleur de l\'équipe';

  @override
  String get teamMgmtColorPickTooltip => 'Appuyez pour choisir une couleur';

  @override
  String get teamMustLoginSaveChanges =>
      'Vous devez être connecté pour enregistrer les modifications';

  @override
  String teamMgmtLogoUploadError(String message) {
    return 'Impossible de télécharger le badge : $message';
  }

  @override
  String get teamMgmtSaveSuccess => 'Modifications enregistrées';

  @override
  String get teamMgmtSectionRosterAccess => 'Effectif et accès';

  @override
  String get teamMgmtEditRosterTitle => 'Modifier l\'équipe';

  @override
  String get teamMgmtEditRosterSubtitle =>
      'Ajouter, supprimer et modifier des joueurs';

  @override
  String get teamMgmtAccessTitle => 'Gérer l\'accès';

  @override
  String get teamMgmtAccessSubtitle =>
      'Inviter des administrateurs ou des spectateurs dans l\'équipe';

  @override
  String get teamMgmtSectionMaintenance => 'Maintenance des données';

  @override
  String get teamMgmtDeleteMatchesTitle => 'Supprimer les correspondances';

  @override
  String get teamMgmtDeleteMatchesSubtitle =>
      'Supprimer des matchs spécifiques du calendrier';

  @override
  String get teamMgmtDeleteAttendanceTitle => 'Supprimer la participation';

  @override
  String get teamMgmtDeleteAttendanceSubtitle =>
      'Supprimer les jours de suivi de présence';

  @override
  String get teamMgmtSectionCritical => 'Zone dangereuse';

  @override
  String get teamAccessLoadMembersError =>
      'Impossible de charger les membres de l\'équipe';

  @override
  String get convSectionMatch => 'Correspondre';

  @override
  String get convRivalLabel => 'Adversaire';

  @override
  String get convVenueLabel => 'Lieu';

  @override
  String get convHome => 'Maison';

  @override
  String get convAway => 'Loin';

  @override
  String get convLocationHint => 'Lieu (facultatif)';

  @override
  String get convLocationFieldHint => 'Lieu ou adresse · indiqué sur l\'image';

  @override
  String get matchFormation => 'Formation';

  @override
  String get matchDeleteEvent => 'Supprimer l\'événement';

  @override
  String get matchConfirmAction => 'Confirmer l\'action';

  @override
  String get matchPickAssistant => 'Sélectionner un assistant';

  @override
  String get matchNoAttendanceOption => 'Aucune présence';

  @override
  String get matchEndGame => 'Fin du match';

  @override
  String get matchMustLoginStart =>
      'Vous devez être connecté pour commencer le match';

  @override
  String get matchStartedOk => 'Le match a commencé avec succès';

  @override
  String get matchMustLoginPause =>
      'Vous devez être connecté pour mettre le match en pause';

  @override
  String get matchStateUpdateFail =>
      'Impossible de mettre à jour le statut de correspondance';

  @override
  String get matchMustLoginResume =>
      'Vous devez être connecté pour reprendre le match';

  @override
  String get matchMustLoginFinish =>
      'Vous devez être connecté pour terminer le match';

  @override
  String get matchOpponentGoal => 'But encaissé';

  @override
  String get matchDeleteEventQuestion =>
      'Supprimer cet événement de match ? Le score, les notes et la discipline seront recalculés.';

  @override
  String get matchEventDeleted => 'Événement supprimé';

  @override
  String get matchEventDeleteFail => 'Impossible de supprimer l\'événement';

  @override
  String get matchLoginRequiredShort => 'Vous devez être connecté';

  @override
  String get matchActionRegisterLogin =>
      'Vous devez être connecté pour enregistrer les actions';

  @override
  String get matchActionRegisterFail => 'Impossible d\'enregistrer l\'action';

  @override
  String get matchActionRegisteredPrefix => 'Action enregistrée pour';

  @override
  String get matchEndGameConfirm =>
      'Mettre fin au match ? Le résultat final sera enregistré.';

  @override
  String matchRegisterActionIntro(String label) {
    return 'Etes-vous sûr de vouloir enregistrer \"$label\" pour';
  }

  @override
  String get dialogDeletePlayerTitle => 'Supprimer un joueur';

  @override
  String get dialogDeleteTeamTitle => 'Supprimer l\'équipe';

  @override
  String get dialogRevokeAccessTitle => 'Supprimer l\'accès';

  @override
  String get dialogInviteUserTitle => 'Inviter un utilisateur';

  @override
  String get accessRevokeBody => 'Supprimer l\'accès de cet utilisateur ?';

  @override
  String get accessRevokeAction => 'Retirer';

  @override
  String get accessRevokedOk => 'Accès supprimé avec succès';

  @override
  String get accessRevokeFail => 'Impossible de supprimer l\'accès';

  @override
  String get accessCannotRemoveSuperAdmin =>
      'Seul le créateur de l\'équipe (super administrateur) peut supprimer un autre super administrateur.';

  @override
  String get accessInviteRole => 'Rôle';

  @override
  String get accessAdminOnlyRevoke =>
      'Seul un administrateur d\'équipe peut supprimer l\'accès.';

  @override
  String get teamColorDefault => 'Par défaut (application verte)';

  @override
  String get teamColorSheetTitle => 'Couleur de l\'équipe';

  @override
  String get teamColorSheetHint =>
      'Barre supérieure, boutons et accents à l\'intérieur de la zone d\'équipe. Les cartes et les zones douces utilisent votre teinte (même subtilité que le vert de l\'application). Vide = vert par défaut.';

  @override
  String get teamSaveDataButton => 'Enregistrer les détails de l\'équipe';

  @override
  String get actionDelete => 'Supprimer';

  @override
  String get actionRemove => 'Retirer';

  @override
  String get teamDeletedSnackbar => 'Équipe supprimée avec succès';

  @override
  String get matchDeleteNeedLogin =>
      'Vous devez être connecté pour supprimer des correspondances';

  @override
  String matchDeleteConfirmBody(String opponent) {
    return 'Supprimer le match contre $opponent ?';
  }

  @override
  String get matchListLoadError => 'Impossible de charger les correspondances';

  @override
  String get matchStatsLoadError =>
      'Impossible de charger les données du match';

  @override
  String get matchListEmpty => 'Aucun match pour cette équipe';

  @override
  String get matchStatusPending => 'Programmé';

  @override
  String get matchStatusFirstHalf => '1ère mi-temps';

  @override
  String get matchStatusHalfTime => 'Mi-temps';

  @override
  String get matchStatusSecondHalf => '2ème mi-temps';

  @override
  String get matchStatusFinished => 'Fini';

  @override
  String get matchLastEvent => 'Dernier événement';

  @override
  String get matchScoreAndTime => 'Score et temps';

  @override
  String get matchQuickScore => 'Score rapide';

  @override
  String get matchShotsOnGoalSection => 'Tirs au but';

  @override
  String get matchEventRivalShot => 'Tir cadré (adversaire)';

  @override
  String get matchRivalShotAddTooltip => 'Ajouter un tir adverse cadré';

  @override
  String get matchRivalShotRemoveTooltip =>
      'Retirer le dernier tir adverse cadré';

  @override
  String get matchNoRivalShotsToRemove => 'Aucun tir adverse à retirer';

  @override
  String get matchFieldAndFormation => 'Emplacement et formation';

  @override
  String get matchSquadTitle => 'Équipe';

  @override
  String get matchSquadHintSpectator =>
      'Mode spectateur : la liste et le pitch sont en lecture seule.';

  @override
  String get matchSquadHintCoach =>
      'Appuyez sur un joueur pour le sélectionner ; appuyez sur le terrain pour aligner ou ouvrir des actions.';

  @override
  String get matchPlayerSentOffCannotReturn =>
      'Un joueur expulsé ne peut pas revenir';

  @override
  String get matchEventsTitle => 'Événements de matchs';

  @override
  String get matchEventsHintSpectator => 'Chronologie du match.';

  @override
  String get matchEventsHintCoach =>
      'Appuyez sur un événement pour le supprimer. Seuls les administrateurs d\'équipe peuvent supprimer des événements.';

  @override
  String get matchEventsEmpty => 'Aucun événement enregistré pour l\'instant';

  @override
  String get matchStartGameButton => 'Commencer le match';

  @override
  String get matchResumeGameButton => 'Reprendre le match';

  @override
  String get matchHalfTimeButton => 'Mi-temps';

  @override
  String get matchPhaseNotStarted => 'Pas commencé';

  @override
  String get matchSpectatorNoPlayerActions =>
      'Mode spectateur : vous ne pouvez pas enregistrer les actions des joueurs';

  @override
  String get matchConfirmGoalTitle => 'Confirmer l\'objectif';

  @override
  String get matchConfirmAddGoalOur =>
      'Ajouter un objectif pour votre équipe ?';

  @override
  String get matchConfirmAddGoalRival => 'Enregistrer un but encaissé ?';

  @override
  String get matchMustLoginRegisterGoals =>
      'Vous devez être connecté pour enregistrer vos objectifs';

  @override
  String get matchGoalsOurTeamFromField =>
      'Les buts de votre équipe sont enregistrés par un joueur sur le terrain';

  @override
  String get matchOpponentGoalRegisteredOk => 'But encaissé enregistré';

  @override
  String get matchGoalSaveFail => 'Impossible de sauver le but';

  @override
  String get matchConvocationLoadError =>
      'Impossible de charger la liste de l\'équipe';

  @override
  String get matchFillAllPositionsBeforeStart =>
      'Placez chaque joueur avant de commencer le match';

  @override
  String get matchConfirmStartTitle => 'Commencer le match';

  @override
  String get matchConfirmStartBody => 'Commencer le match ?';

  @override
  String get matchConfirmHalfTimeTitle => 'Aller à la mi-temps';

  @override
  String get matchConfirmHalfTimeBody => 'Passer à la mi-temps ?';

  @override
  String get matchConfirmResumeTitle => 'Reprendre le match';

  @override
  String get matchConfirmResumeBody => 'Commencer la seconde mi-temps ?';

  @override
  String get matchEndGameDialogBody =>
      'Mettre fin au match ? Les statistiques seront enregistrées.';

  @override
  String get matchEndGameAction => 'Fin';

  @override
  String get matchSentOffDoubleYellow => 'expulsé (deuxième jaune)';

  @override
  String get matchSentOffSimple => 'envoyé';

  @override
  String matchUnknownPlayerId(int id) {
    return 'Joueur $id';
  }

  @override
  String get matchLiveFormationRegistered => 'Formation sauvegardée';

  @override
  String matchLiveFormationLine(String formation) {
    return 'Formation : $formation';
  }

  @override
  String get matchLiveSubstitutionEnters => 'Remplacement · Activé';

  @override
  String get matchLiveSubstitutionLeaves => '· Désactivé';

  @override
  String get matchLivePeriodFallback => 'Changement de période ou de statut';

  @override
  String get matchLiveGoalBy => 'Objectif par';

  @override
  String get matchLiveAssistOpening => '(assister';

  @override
  String get matchLiveAssistClosing => ')';

  @override
  String get matchLiveConcededDefault => 'But encaissé';

  @override
  String get matchLiveOwnGoal => 'But contre son camp ·';

  @override
  String get matchLiveYellowCard => 'Carton jaune:';

  @override
  String get matchLiveRedCard => 'Carton rouge:';

  @override
  String get matchLiveSaveBy => 'Enregistrer par';

  @override
  String matchLiveSaveWithNote(String note) {
    return 'Enregistrer · $note';
  }

  @override
  String get matchLiveSaveOnly => 'Sauvegarder';

  @override
  String get matchLiveKeyPass => 'Passe clé :';

  @override
  String get matchLiveGoodPass => 'Bonne passe :';

  @override
  String get matchLiveBadPass => 'Mauvaise passe :';

  @override
  String get matchLiveGoodPlay => 'Bon jeu :';

  @override
  String get matchLiveBadPlay => 'Mauvais jeu :';

  @override
  String get matchLiveBallRecovery => 'Ballon gagné :';

  @override
  String get matchLiveEvent => 'Événement';

  @override
  String matchLiveEventLine(String label, String note) {
    return '$label : $note';
  }

  @override
  String get matchNoteFirstHalfStart => 'Coup d\'envoi de la première mi-temps';

  @override
  String get matchNoteSecondHalfStart =>
      'Coup d\'envoi de la deuxième mi-temps';

  @override
  String get matchNoteMatchFinished => 'À temps plein';

  @override
  String get matchActionLabelGoal => 'But';

  @override
  String get matchActionLabelGoodPass => 'Bonne passe';

  @override
  String get matchActionLabelGoodPlay => 'Bon jeu';

  @override
  String get matchActionLabelBallRecovery => 'Récupération du ballon';

  @override
  String get matchActionLabelShot => 'Tir';

  @override
  String get matchActionLabelYellowCard => 'Carton jaune';

  @override
  String get matchActionLabelRedCard => 'Carton rouge';

  @override
  String get matchActionLabelBadPass => 'Mauvaise passe';

  @override
  String get matchActionLabelBadPlay => 'Mauvais jeu';

  @override
  String get matchActionLabelKeyPass => 'Passe-clé';

  @override
  String get matchGoalRegisteredPrefix => 'Objectif enregistré pour';

  @override
  String get attendanceSaveHint =>
      'Appuyez sur ✓ pour présent ou X pour absent, puis enregistrez pour le jour sélectionné.';

  @override
  String get attendanceSaveButton => 'Enregistrer la fréquentation';

  @override
  String get attendanceSaveNeedLogin =>
      'Vous devez être connecté pour enregistrer votre participation';

  @override
  String get attendanceSaveTeamLoadError => 'Impossible de charger l\'équipe';

  @override
  String get attendanceSaveInProgress => 'Économie…';

  @override
  String get attendanceSaveSuccess => 'Participation enregistrée avec succès';

  @override
  String get convDatetimeSectionTitle => 'Date et heures';

  @override
  String get convPickDateTooltip => 'Choisir la date';

  @override
  String get tooltipChange => 'Changement';

  @override
  String get attendanceDeleteLoadError =>
      'Impossible de charger les jours de présence';

  @override
  String get attendanceDeleteEmpty => 'Aucun jour de formation enregistré';

  @override
  String get attendanceDeleteNeedLogin =>
      'Vous devez être connecté pour supprimer la participation';

  @override
  String get teamDeleteNavTitle => 'Supprimer l\'équipe';

  @override
  String get teamDeleteNavSubtitle =>
      'Retirez le club et cachez-le de chez vous';

  @override
  String get teamDeleteNeedLogin =>
      'Vous devez être connecté pour supprimer l\'équipe';

  @override
  String get teamDeleteConfirmBody =>
      'Supprimer cette équipe ? Cela ne peut pas être annulé.';

  @override
  String attendanceDeleteConfirmBody(String date) {
    return 'Supprimer la participation pour $date ?';
  }

  @override
  String get dialogClose => 'Fermer';

  @override
  String get convocationNotesTitle => 'Remarques';

  @override
  String get convocationNotesHint => 'Kit, ponctualité, message à l\'équipe…';

  @override
  String get convocationSavedSuccess => 'Appel enregistré avec succès';

  @override
  String get convocationImageSectionMatchDetails => 'Détails du match';

  @override
  String get convocationImageLabelDate => 'Date';

  @override
  String get convocationImageLabelMatchTime => 'Heure du coup d\'envoi';

  @override
  String get convocationImageLabelCallTime => 'Heure de rendez-vous';

  @override
  String get convocationImageLabelVenue => 'Lieu';

  @override
  String get convocationImageSectionSquad => 'Joueurs convoqués';

  @override
  String get convocationImageObservationsTitle => 'Remarques';

  @override
  String get convocationImagePlayerFallback => 'Joueur';

  @override
  String matchSummaryVs(String opponent) {
    return 'contre $opponent';
  }

  @override
  String get matchVenueHome => 'Maison';

  @override
  String get matchVenueAway => 'Loin';

  @override
  String get matchScoreForLabel => 'Pour';

  @override
  String get matchScoreAgainstLabel => 'Contre';

  @override
  String get matchStatsScoreFinal => 'Score final';

  @override
  String get matchStatsScoreLive => 'Score';

  @override
  String get matchStatsLoadingSummary => 'Chargement du résumé du match…';

  @override
  String get matchStatsSectionField => 'Présentation finale';

  @override
  String matchStatsFormationChip(String formation) {
    return 'Formation : $formation';
  }

  @override
  String get matchStatsFieldDispositionHint =>
      'Disposition basée sur les positions enregistrées à la fin du match.';

  @override
  String get matchStatsSectionTimeline => 'Chronologie';

  @override
  String get matchStatsTimelineEmpty => 'Aucun événement enregistré';

  @override
  String get matchStatsTimelineEmptyHint =>
      'Les buts, les remplaçants et les cartes apparaîtront ici une fois connectés au match.';

  @override
  String get matchStatsMinutesPlayed => 'Minutes jouées';

  @override
  String get matchStatsStatGoals => 'Objectifs';

  @override
  String get matchStatsStatAssists => 'Aides';

  @override
  String get matchStatsStatGoodPasses => 'Bonnes passes';

  @override
  String get matchStatsStatBadPasses => 'Mauvaises passes';

  @override
  String get matchStatsStatGoodPlays => 'Bonnes pièces';

  @override
  String get matchStatsStatBadPlays => 'Mauvaises pièces';

  @override
  String get matchStatsOurGoalChip => 'Objectif pour';

  @override
  String get matchStatsOwnGoalChip => 'But contre son camp';

  @override
  String get matchListLoading => 'Chargement des matchs…';

  @override
  String get matchListEmptyStateTitle => 'Aucun match pour l\'instant';

  @override
  String get matchListEmptyStateBody =>
      'Les correspondances que vous créez à partir d’une commande s’afficheront ici. Déroulez vers le bas pour actualiser.';

  @override
  String get matchListCalendarTitle => 'Calendrier';

  @override
  String matchListElapsedTime(String time) {
    return 'Heure : $time';
  }

  @override
  String get matchListHintLineupStart =>
      'Appuyez pour vous aligner et commencer';

  @override
  String get matchListHintManageResume => 'Appuyez pour gérer ou reprendre';

  @override
  String get matchListHintViewStats => 'Appuyez pour afficher les statistiques';

  @override
  String get matchLineupSquadTitle => 'Équipe de match';

  @override
  String get matchLineupStarters => 'Entrées';

  @override
  String get matchLineupSubstitutes => 'Substituts';

  @override
  String get matchLineupStarterTag => 'Démarreur';

  @override
  String get matchLineupSubstituteTag => 'Remplaçant';

  @override
  String get matchFieldSelectPlayerFirst =>
      'Sélectionnez d\'abord un joueur dans la liste';

  @override
  String get matchFieldMaxPlayersExpulsionRule =>
      'On ne peut pas avoir plus de joueurs sur le terrain. Chaque joueur expulsé doit laisser un emplacement libre.';

  @override
  String get matchConvocationTableEmpty =>
      'Aucun joueur convoqué pour ce match';

  @override
  String get matchDeletedSuccess => 'Correspondance supprimée avec succès';

  @override
  String get matchEventLegacyActionRegistered => 'Action enregistrée';
}
