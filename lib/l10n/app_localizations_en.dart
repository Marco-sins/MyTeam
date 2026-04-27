// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'My Team';

  @override
  String get authWelcomeBack => 'Welcome back';

  @override
  String get authCreateAccount => 'Create your account';

  @override
  String get authHaveAccountLogin => 'Already have an account? Sign in';

  @override
  String get authNoAccountRegister => 'No account? Register';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginEmailError => 'Enter your email';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginPasswordMinError => 'At least 6 characters';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get loginForgotPassword => 'Forgot password';

  @override
  String get registerFullNameLabel => 'Full name';

  @override
  String get registerNameError => 'Please enter your name';

  @override
  String get registerEmailInvalid => 'Invalid email';

  @override
  String get registerSubmit => 'Create account';

  @override
  String get authCheckEmailTitle => 'Check your email';

  @override
  String get authUnderstand => 'OK';

  @override
  String authRegisterEmailConfirm(String email) {
    return 'We\'ve sent a link to $email. Open it to activate your account before signing in. Check your spam folder too.';
  }

  @override
  String get authRegisterEmailActive =>
      'Your account is active. Check your inbox for a verification or welcome email (including spam).';

  @override
  String get homeLogoutTooltip => 'Sign out';

  @override
  String get homeInvitations => 'Invitations';

  @override
  String get homeNewTeam => 'New team';

  @override
  String get homeLoadingTeams => 'Loading your teams…';

  @override
  String get homeRetry => 'Retry';

  @override
  String get homeYourPanel => 'Your dashboard';

  @override
  String get homeTeamCountOne => 'You have 1 team. Tap a card to open it.';

  @override
  String homeTeamCountMany(int count) {
    return 'You have $count teams. Tap a card to open it.';
  }

  @override
  String get homeEmptyTitle => 'You don\'t have any teams yet';

  @override
  String get homeEmptySubtitle =>
      'Create your first team with the floating button or check if you have pending invitations.';

  @override
  String get homeEmptyHintNewTeam => 'New team: basic details and badge';

  @override
  String get homeEmptyHintInvitations => 'Invitations: join an existing team';

  @override
  String get languageSpanish => 'Spanish (ES)';

  @override
  String get languageEnglish => 'English (EN)';

  @override
  String get languageFrench => 'French (FR)';

  @override
  String get languageItalian => 'Italian (IT)';

  @override
  String get languageSelectorTooltip => 'App language';

  @override
  String get roleSuperAdmin => 'Super admin';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get rolePlayer => 'Player';

  @override
  String get roleExternal => 'External';

  @override
  String get roleSpectator => 'Spectator';

  @override
  String get tableColumnPlayer => 'Player';

  @override
  String get tableColumnPhoto => 'Photo';

  @override
  String get tableColumnAttends => 'Present';

  @override
  String get tableColumnAbsent => 'Absent';

  @override
  String get convocationCallAll => 'All';

  @override
  String get convocationPlayerStatus => 'Status';

  @override
  String get convocationEmptyRoster => 'No players in the squad';

  @override
  String get convocationToggleHint =>
      'Call everyone at once or tap each player to toggle Yes / No.';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get accessInviteSpectatorOnlyHint =>
      'As an administrator, you can only invite spectators.';

  @override
  String get accessInviteSend => 'Send invitation';

  @override
  String get accessInviteNeedAuth =>
      'You must be signed in to send invitations';

  @override
  String get accessAdminOnlyInvite =>
      'Only a team admin can invite or remove access.';

  @override
  String get accessUsersWithAccess => 'Users with access';

  @override
  String get accessListBlurb =>
      'Live list: updates when someone gains or loses access. Each row shows name and email (profiles) to identify the person.';

  @override
  String get accessPeopleCountSingle => '1 person';

  @override
  String accessPeopleCountMany(int count) {
    return '$count people';
  }

  @override
  String get accessEmptyMembersTitle => 'Nobody else has access yet.';

  @override
  String get accessEmptyMembersHint => 'Invite by email with the button below.';

  @override
  String get accessProfileNoName => 'No name on profile';

  @override
  String get accessProfileNoEmail =>
      'Email unavailable (check profile in the app)';

  @override
  String get accessNamePrefix => 'Name: ';

  @override
  String get accessEmailPrefix => 'Email: ';

  @override
  String get accessRolePrefix => 'Role: ';

  @override
  String get accessYou => 'You';

  @override
  String accessInviteSent(String email, String role) {
    return 'Invitation sent to $email as $role.';
  }

  @override
  String get navMenuTooltip => 'Team menu';

  @override
  String get navMyTeams => 'My teams';

  @override
  String get navTeamHomeSubtitle => 'Team home';

  @override
  String get navAttendance => 'Attendance';

  @override
  String get navConvocation => 'Call-up';

  @override
  String get navMatch => 'Match';

  @override
  String get navManagement => 'Management';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get screenAttendance => 'Attendance';

  @override
  String get screenConvocation => 'Call-up';

  @override
  String get screenConvocationGenerated => 'Call-up image';

  @override
  String get screenMatches => 'Matches';

  @override
  String get screenMatchLive => 'Live match';

  @override
  String get screenMatchDetail => 'Match details';

  @override
  String get screenDeleteMatch => 'Delete match';

  @override
  String get screenDeleteAttendance => 'Delete attendance';

  @override
  String get screenTeamManagement => 'Team management';

  @override
  String get screenTeamAccess => 'Team access';

  @override
  String get screenRoster => 'Squad';

  @override
  String get screenSelectLocation => 'Pick location';

  @override
  String get screenNewTeamPage => 'New team';

  @override
  String get screenAddPlayer => 'Add player';

  @override
  String get screenEditPlayer => 'Edit player';

  @override
  String get shareImageTooltip => 'Share image';

  @override
  String convocationShareText(String teamName) {
    return '$teamName call-up';
  }

  @override
  String get backToTeam => 'Back to team';

  @override
  String get dialogNoAccessTitle => 'No team access';

  @override
  String get dialogNoAccessBody =>
      'You no longer have access to this team. It has been removed from your dashboard and you cannot re-enter until an administrator invites you again.';

  @override
  String get dialogLeaveTeamTitle => 'Leave team';

  @override
  String leaveTeamPromptExternal(String teamName) {
    return 'Leave $teamName? You will no longer see the squad or matches until an administrator invites you again.';
  }

  @override
  String leaveTeamPromptAdmin(String teamName) {
    return 'Leave $teamName as an admin? You will lose management permissions; you can only return if a super admin invites you again.';
  }

  @override
  String leaveTeamPromptPlayer(String teamName) {
    return 'Leave $teamName as a player? You will be removed from the squad until you are registered again.';
  }

  @override
  String leaveTeamPromptGeneric(String teamName) {
    return 'Leave $teamName?';
  }

  @override
  String get leaveTeamButton => 'Leave team';

  @override
  String get snackbarLeftTeam => 'You left the team';

  @override
  String get teamCheckingAccess => 'Checking access…';

  @override
  String get teamLoadingRoster => 'Loading squad…';

  @override
  String get teamEmptyRosterTitle => 'No players in the squad yet';

  @override
  String get teamEmptyRosterHint => 'Add them from Management → Edit squad.';

  @override
  String get teamHeaderLeaveShort => 'Leave';

  @override
  String get teamPlayerCountOne => '1 player';

  @override
  String teamPlayerCountMany(int count) {
    return '$count players';
  }

  @override
  String get teamMustLoginAddPlayers => 'You must be signed in to add players';

  @override
  String get teamMustLoginEditPlayers =>
      'You must be signed in to edit players';

  @override
  String get teamMustLoginDeletePlayers =>
      'You must be signed in to delete players';

  @override
  String get dialogDeletePlayerLead => 'Are you sure you want to delete ';

  @override
  String get teamManagementLogoLabel => 'Badge';

  @override
  String get teamManagementLogoTapHint => 'Tap to change';

  @override
  String get teamManagementNameLabel => 'Team name';

  @override
  String get teamManagementNameHint => 'e.g. Riverside FC';

  @override
  String get accessDefaultUserName => 'User';

  @override
  String get teamMgmtSectionTeamData => 'Team details';

  @override
  String get teamMgmtColorRowLabel => 'Team color';

  @override
  String get teamMgmtColorPickTooltip => 'Tap to pick a color';

  @override
  String get teamMustLoginSaveChanges =>
      'You must be signed in to save changes';

  @override
  String teamMgmtLogoUploadError(String message) {
    return 'Could not upload badge: $message';
  }

  @override
  String get teamMgmtSaveSuccess => 'Changes saved';

  @override
  String get teamMgmtSectionRosterAccess => 'Squad & access';

  @override
  String get teamMgmtEditRosterTitle => 'Edit squad';

  @override
  String get teamMgmtEditRosterSubtitle => 'Add, remove and edit players';

  @override
  String get teamMgmtAccessTitle => 'Manage access';

  @override
  String get teamMgmtAccessSubtitle =>
      'Invite admins or spectators to the team';

  @override
  String get teamMgmtScoringTitle => 'Rating weights';

  @override
  String get teamMgmtScoringSubtitle =>
      'Change how much each event adds to the match rating';

  @override
  String get teamScoringScreenTitle => 'Match rating weights';

  @override
  String get teamScoringSave => 'Save';

  @override
  String get teamScoringAddEvent => 'Add event';

  @override
  String get teamScoringAddDialogTitle => 'New custom event';

  @override
  String get teamScoringEventName => 'Name as in match note';

  @override
  String get teamScoringPoints => 'Points';

  @override
  String get teamScoringUnnamed => '(Unnamed)';

  @override
  String get teamScoringInvalidNumber => 'Check the numbers entered';

  @override
  String get teamScoringDuplicateName => 'Two events cannot have the same name';

  @override
  String get teamScoringCustomHint =>
      'Must match the event note text (case-insensitive)';

  @override
  String get teamScoringDeleteTooltip => 'Remove from list';

  @override
  String get teamScoringGoalScorer => 'Goal';

  @override
  String get teamScoringGoalAssist => 'Assist';

  @override
  String get teamScoringEventOwnGoal => 'Own goal';

  @override
  String get teamScoringEventGoalConceded => 'Goal conceded';

  @override
  String get teamScoringParadaIncreible => 'Great save (incredible)';

  @override
  String get teamScoringPaseClaveNota => 'Key pass';

  @override
  String get teamScoringJugadaClaveNota => 'Key play';

  @override
  String get teamScoringTiroNota => 'Shot';

  @override
  String get teamScoringAmarillaNota => 'Yellow card';

  @override
  String get teamScoringRojaNota => 'Red card';

  @override
  String get teamScoringCantadaNota => 'Howler';

  @override
  String get teamImportPlayerTitle => 'Import from another team';

  @override
  String get teamImportPlayerSubtitle =>
      'Choose a team you manage and a player. Name, contact details, photo and positions are copied; statistics for this team are new (zeroed).';

  @override
  String get teamImportPlayerStatsHint => 'Old team stats are not transferred.';

  @override
  String get teamImportPlayerButton => 'Import from another team';

  @override
  String get teamImportPlayerSelectTeam => 'Source team';

  @override
  String get teamImportPlayerNoSourceTeams =>
      'You have no other team where you are an admin or super admin.';

  @override
  String get teamImportPlayerPickTeamFirst =>
      'Select a team to list its players.';

  @override
  String get teamImportPlayerEmptyRoster => 'This squad has no players.';

  @override
  String get teamImportPlayerConfirmTitle => 'Import player';

  @override
  String teamImportPlayerConfirmBody(String playerName, String sourceTeamName) {
    return 'Import $playerName from $sourceTeamName into this squad? Their stats here start at zero.';
  }

  @override
  String get teamImportPlayerConfirmAction => 'Import';

  @override
  String get teamImportPlayerSuccess => 'Player imported';

  @override
  String get teamMgmtSectionMaintenance => 'Data maintenance';

  @override
  String get teamMgmtDeleteMatchesTitle => 'Delete matches';

  @override
  String get teamMgmtDeleteMatchesSubtitle =>
      'Remove specific matches from the schedule';

  @override
  String get teamMgmtDeleteAttendanceTitle => 'Delete attendance';

  @override
  String get teamMgmtDeleteAttendanceSubtitle =>
      'Remove attendance tracking days';

  @override
  String get teamMgmtSectionCritical => 'Danger zone';

  @override
  String get teamAccessLoadMembersError => 'Could not load team members';

  @override
  String get convSectionMatch => 'Match';

  @override
  String get convRivalLabel => 'Opponent';

  @override
  String get convVenueLabel => 'Venue';

  @override
  String get convHome => 'Home';

  @override
  String get convAway => 'Away';

  @override
  String get convLocationHint => 'Place (optional)';

  @override
  String get convLocationFieldHint => 'Venue or address · shown on the image';

  @override
  String get matchFormation => 'Formation';

  @override
  String get matchDeleteEvent => 'Delete event';

  @override
  String get matchConfirmAction => 'Confirm action';

  @override
  String get matchPickAssistant => 'Select assistant';

  @override
  String get matchNoAttendanceOption => 'No attendance';

  @override
  String get matchEndGame => 'End match';

  @override
  String get matchMustLoginStart => 'You must be signed in to start the match';

  @override
  String get matchStartedOk => 'Match started successfully';

  @override
  String get matchMustLoginPause => 'You must be signed in to pause the match';

  @override
  String get matchStateUpdateFail => 'Could not update match status';

  @override
  String get matchMustLoginResume =>
      'You must be signed in to resume the match';

  @override
  String get matchMustLoginFinish => 'You must be signed in to end the match';

  @override
  String get matchOpponentGoal => 'Goal against';

  @override
  String get matchDeleteEventQuestion =>
      'Delete this match event? Score, notes and discipline will be recalculated.';

  @override
  String get matchEventDeleted => 'Event deleted';

  @override
  String get matchEventDeleteFail => 'Could not delete the event';

  @override
  String get matchLoginRequiredShort => 'You must be signed in';

  @override
  String get matchActionRegisterLogin => 'You must be signed in to log actions';

  @override
  String get matchActionRegisterFail => 'Could not save the action';

  @override
  String get matchActionRegisteredPrefix => 'Action saved for ';

  @override
  String get matchEndGameConfirm =>
      'End the match? The final result will be saved.';

  @override
  String matchRegisterActionIntro(String label) {
    return 'Are you sure you want to log \"$label\" for ';
  }

  @override
  String get dialogDeletePlayerTitle => 'Delete player';

  @override
  String get dialogDeleteTeamTitle => 'Delete team';

  @override
  String get dialogRevokeAccessTitle => 'Remove access';

  @override
  String get dialogInviteUserTitle => 'Invite user';

  @override
  String get accessRevokeBody => 'Remove this user\'s access?';

  @override
  String get accessRevokeAction => 'Remove';

  @override
  String get accessRevokedOk => 'Access removed successfully';

  @override
  String get accessRevokeFail => 'Could not remove access';

  @override
  String get accessCannotRemoveSuperAdmin =>
      'Only the team creator (super admin) can remove another super admin.';

  @override
  String get accessInviteRole => 'Role';

  @override
  String get accessAdminOnlyRevoke => 'Only a team admin can remove access.';

  @override
  String get teamColorDefault => 'Default (app green)';

  @override
  String get teamColorSheetTitle => 'Team color';

  @override
  String get teamColorSheetHint =>
      'Top bar, buttons and accents inside the team area. Cards and soft areas use your tint (same subtlety as the app green). Empty = default green.';

  @override
  String get teamSaveDataButton => 'Save team details';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionRemove => 'Remove';

  @override
  String get teamDeletedSnackbar => 'Team deleted successfully';

  @override
  String get matchDeleteNeedLogin => 'You must be signed in to delete matches';

  @override
  String matchDeleteConfirmBody(String opponent) {
    return 'Delete the match against $opponent?';
  }

  @override
  String get matchListLoadError => 'Could not load matches';

  @override
  String get matchStatsLoadError => 'Could not load match data';

  @override
  String get matchListEmpty => 'No matches for this team';

  @override
  String get matchStatusPending => 'Scheduled';

  @override
  String get matchStatusFirstHalf => '1st half';

  @override
  String get matchStatusHalfTime => 'Half-time';

  @override
  String get matchStatusSecondHalf => '2nd half';

  @override
  String get matchStatusFinished => 'Finished';

  @override
  String get matchLastEvent => 'Latest event';

  @override
  String get matchScoreAndTime => 'Score and time';

  @override
  String get matchQuickScore => 'Quick score';

  @override
  String get matchLiveStatsCardTitle => 'Match stats';

  @override
  String get matchShotsOnGoalSection => 'Shots on goal';

  @override
  String get matchEventRivalShot => 'Shot on goal (opponent)';

  @override
  String get matchRivalShotAddTooltip => 'Add an opponent shot on goal';

  @override
  String get matchRivalShotRemoveTooltip => 'Remove last opponent shot on goal';

  @override
  String get matchNoRivalShotsToRemove => 'No opponent shots on goal to remove';

  @override
  String get matchSpectatorCannotStart =>
      'Only coaches and admins can start the match.';

  @override
  String get matchFoulsAndCornersSection => 'Fouls and corners';

  @override
  String get matchFoulsShort => 'Fouls';

  @override
  String get matchCornersShort => 'Corners';

  @override
  String get matchOffsidesShort => 'Offsides';

  @override
  String get matchEventOffside => 'Offside';

  @override
  String get matchEventRivalOffside => 'Rival offside';

  @override
  String get matchYellowCardsShort => 'Yellow cards';

  @override
  String get matchRedCardsShort => 'Red cards';

  @override
  String get matchRivalYellowCardNote => 'Yellow card (opponent)';

  @override
  String get matchRivalRedCardNote => 'Red card (opponent)';

  @override
  String get matchCounterAddTooltip => 'Add one';

  @override
  String get matchCounterRemoveTooltip => 'Remove last';

  @override
  String get matchNoCounterToRemove => 'Nothing to remove';

  @override
  String get matchActionLabelFoul => 'Foul';

  @override
  String get matchFieldAndFormation => 'Pitch and formation';

  @override
  String get matchFieldBenchTitle => 'Bench';

  @override
  String get matchFieldBenchHint =>
      'Long-press a substitute and drop them on a position (sub or open slot).';

  @override
  String get matchSquadTitle => 'Squad';

  @override
  String get matchSquadHintSpectator =>
      'Spectator mode: list and pitch are view-only.';

  @override
  String get matchSquadHintCoach =>
      'Tap a player to select; tap the pitch to line up or open actions.';

  @override
  String get matchPlayerSentOffCannotReturn =>
      'Sent-off player cannot come back on';

  @override
  String get matchEventsTitle => 'Match events';

  @override
  String get matchEventsHintSpectator => 'Match timeline.';

  @override
  String get matchEventsHintCoach =>
      'Tap an event to delete it. Only team admins can remove events.';

  @override
  String get matchEventsEmpty => 'No events recorded yet';

  @override
  String get matchStartGameButton => 'Start match';

  @override
  String get matchResumeGameButton => 'Resume match';

  @override
  String get matchHalfTimeButton => 'Half-time';

  @override
  String get matchPhaseNotStarted => 'Not started';

  @override
  String get matchSpectatorNoPlayerActions =>
      'Spectator mode: you cannot log player actions';

  @override
  String get matchConfirmGoalTitle => 'Confirm goal';

  @override
  String get matchConfirmAddGoalOur => 'Add a goal for your team?';

  @override
  String get matchConfirmAddGoalRival => 'Register a goal against?';

  @override
  String get matchMustLoginRegisterGoals =>
      'You must be signed in to log goals';

  @override
  String get matchGoalsOurTeamFromField =>
      'Your team\'s goals are logged from a player on the pitch';

  @override
  String get matchOpponentGoalRegisteredOk => 'Goal against saved';

  @override
  String get matchGoalSaveFail => 'Could not save the goal';

  @override
  String get matchConvocationLoadError => 'Could not load the squad list';

  @override
  String get matchFillAllPositionsBeforeStart =>
      'Place every player before starting the match';

  @override
  String get matchConfirmStartTitle => 'Start match';

  @override
  String get matchConfirmStartBody => 'Start the match?';

  @override
  String get matchConfirmHalfTimeTitle => 'Go to half-time';

  @override
  String get matchConfirmHalfTimeBody => 'Move to half-time?';

  @override
  String get matchConfirmResumeTitle => 'Resume match';

  @override
  String get matchConfirmResumeBody => 'Start the second half?';

  @override
  String get matchEndGameDialogBody =>
      'End the match? Statistics will be saved.';

  @override
  String get matchEndGameAction => 'End';

  @override
  String get matchSentOffDoubleYellow => ' sent off (second yellow)';

  @override
  String get matchSentOffSimple => ' sent off';

  @override
  String matchUnknownPlayerId(int id) {
    return 'Player $id';
  }

  @override
  String get matchLiveFormationRegistered => 'Formation saved';

  @override
  String matchLiveFormationLine(String formation) {
    return 'Formation: $formation';
  }

  @override
  String get matchLiveSubstitutionEnters => 'Substitution · On ';

  @override
  String get matchLiveSubstitutionLeaves => ' · Off ';

  @override
  String get matchLiveSubstitutionToFreeSlot => ' (open slot / bench)';

  @override
  String get matchLiveMinuteSquad => 'Lineup';

  @override
  String get matchLivePeriodFallback => 'Period or status change';

  @override
  String get matchLiveGoalBy => 'Goal by ';

  @override
  String get matchLiveAssistOpening => ' (assist ';

  @override
  String get matchLiveAssistClosing => ')';

  @override
  String get matchLiveConcededDefault => 'Conceded goal';

  @override
  String get matchLiveOwnGoal => 'Own goal · ';

  @override
  String get matchLiveYellowCard => 'Yellow card: ';

  @override
  String get matchLiveRedCard => 'Red card: ';

  @override
  String get matchLiveSaveBy => 'Save by ';

  @override
  String matchLiveSaveWithNote(String note) {
    return 'Save · $note';
  }

  @override
  String get matchLiveSaveOnly => 'Save';

  @override
  String get matchLiveKeyPass => 'Key pass: ';

  @override
  String get matchLiveGoodPass => 'Good pass: ';

  @override
  String get matchLiveBadPass => 'Bad pass: ';

  @override
  String get matchLiveGoodPlay => 'Good play: ';

  @override
  String get matchLiveBadPlay => 'Bad play: ';

  @override
  String get matchLiveBallRecovery => 'Ball won: ';

  @override
  String get matchLiveGoodSave => 'Good save: ';

  @override
  String get matchLiveShot => 'Shot: ';

  @override
  String get matchLiveFoul => 'Foul: ';

  @override
  String get matchLiveCantada => 'Howler: ';

  @override
  String get matchLiveEvent => 'Event';

  @override
  String matchLiveEventLine(String label, String note) {
    return '$label: $note';
  }

  @override
  String get matchNoteFirstHalfStart => 'First half kickoff';

  @override
  String get matchNoteSecondHalfStart => 'Second half kickoff';

  @override
  String get matchNoteMatchFinished => 'Full time';

  @override
  String get matchActionLabelGoal => 'Goal';

  @override
  String get matchActionLabelGoodPass => 'Good pass';

  @override
  String get matchActionLabelGoodPlay => 'Good play';

  @override
  String get matchActionLabelBallRecovery => 'Ball recovery';

  @override
  String get matchActionLabelShot => 'Shot';

  @override
  String get matchActionLabelYellowCard => 'Yellow card';

  @override
  String get matchActionLabelRedCard => 'Red card';

  @override
  String get matchActionLabelBadPass => 'Bad pass';

  @override
  String get matchActionLabelBadPlay => 'Bad play';

  @override
  String get matchActionLabelKeyPass => 'Key pass';

  @override
  String get matchActionLabelGoodSave => 'Good save';

  @override
  String get matchActionLabelCantada => 'Howler';

  @override
  String get matchGoalRegisteredPrefix => 'Goal saved for ';

  @override
  String get attendanceSaveHint =>
      'Tap ✓ for present or X for absent, then save for the selected day.';

  @override
  String get attendanceSaveButton => 'Save attendance';

  @override
  String get attendanceSaveNeedLogin =>
      'You must be signed in to save attendance';

  @override
  String get attendanceSaveTeamLoadError => 'Could not load the team squad';

  @override
  String get attendanceSaveInProgress => 'Saving…';

  @override
  String get attendanceSaveSuccess => 'Attendance saved successfully';

  @override
  String get convDatetimeSectionTitle => 'Date and times';

  @override
  String get convPickDateTooltip => 'Pick date';

  @override
  String get tooltipChange => 'Change';

  @override
  String get attendanceDeleteLoadError => 'Could not load attendance days';

  @override
  String get attendanceDeleteEmpty => 'No training days recorded';

  @override
  String get attendanceDeleteNeedLogin =>
      'You must be signed in to delete attendance';

  @override
  String get teamDeleteNavTitle => 'Delete team';

  @override
  String get teamDeleteNavSubtitle => 'Remove the club and hide it from home';

  @override
  String get teamDeleteNeedLogin => 'You must be signed in to delete the team';

  @override
  String get teamDeleteConfirmBody =>
      'Delete this team? This cannot be undone.';

  @override
  String attendanceDeleteConfirmBody(String date) {
    return 'Delete attendance for $date?';
  }

  @override
  String get dialogClose => 'Close';

  @override
  String get convocationNotesTitle => 'Notes';

  @override
  String get convocationNotesHint => 'Kit, punctuality, message to the squad…';

  @override
  String get convocationSavedSuccess => 'Call-up saved successfully';

  @override
  String get convocationImageSectionMatchDetails => 'Match details';

  @override
  String get convocationImageLabelTeam => 'Team';

  @override
  String get convocationImageLabelFixture => 'Fixture';

  @override
  String get convocationImageLabelCallDateTime => 'Call date and time';

  @override
  String get convocationImageLabelMeetingVenue => 'Meeting point';

  @override
  String get convocationImageLabelMatchVenue => 'Match venue';

  @override
  String get convocationImageVenueHomeInstallations => 'Club facilities';

  @override
  String get convocationImageLabelDate => 'Date';

  @override
  String get convocationImageLabelMatchTime => 'Kick-off time';

  @override
  String get convocationImageLabelCallTime => 'Meet-up time';

  @override
  String get convocationImageLabelVenue => 'Venue';

  @override
  String get convocationImageSectionSquad => 'Called-up players';

  @override
  String get convocationImageObservationsTitle => 'Notes';

  @override
  String get convocationImagePlayerFallback => 'Player';

  @override
  String get convocationImageSectionMatchDetailsSubtitle =>
      'Date, times and venue — take your time reading';

  @override
  String get convocationImageLabelMatchKickoff => 'KICK-OFF TIME (MATCH START)';

  @override
  String get convocationImageLabelCallArrival => 'MEET-UP TIME (ARRIVAL)';

  @override
  String get convocationImageCallTimeReminder =>
      'Important: arrive before this time, not when the match starts.';

  @override
  String get convocationImageMapLinkIntro =>
      'On your phone you can open this link to see the place on the map:';

  @override
  String get convocationImagePlaceHomeHeadline => 'HOME MATCH';

  @override
  String get convocationImagePlaceHomeDetail => 'We play on our home ground.';

  @override
  String get convocationImagePlaceAwayHeadline => 'AWAY MATCH';

  @override
  String get convocationImagePlaceAwayNoAddressDetail =>
      'The club will confirm the exact address. Ask your coach.';

  @override
  String matchSummaryVs(String opponent) {
    return 'vs $opponent';
  }

  @override
  String get matchVenueHome => 'Home';

  @override
  String get matchVenueAway => 'Away';

  @override
  String get matchScoreForLabel => 'For';

  @override
  String get matchScoreAgainstLabel => 'Against';

  @override
  String get matchStatsScoreFinal => 'Final score';

  @override
  String get matchStatsScoreLive => 'Score';

  @override
  String get matchStatsTeamNamePlaceholder => 'Team';

  @override
  String get matchStatsLoadingSummary => 'Loading match summary…';

  @override
  String get matchStatsSectionField => 'Lineup';

  @override
  String matchStatsFormationChip(String formation) {
    return 'Formation: $formation';
  }

  @override
  String get matchStatsFieldDispositionHint =>
      'Starting eleven layout from saved positions in the lineup.';

  @override
  String get matchStatsSectionTimeline => 'Timeline';

  @override
  String get matchStatsTimelineEmpty => 'No events recorded';

  @override
  String get matchStatsTimelineEmptyHint =>
      'Goals, subs and cards will appear here once logged in the match.';

  @override
  String get matchStatsMinutesPlayed => 'Minutes played';

  @override
  String get matchStatsStatGoals => 'Goals';

  @override
  String get matchStatsStatAssists => 'Assists';

  @override
  String get matchStatsStatGoodPasses => 'Good passes';

  @override
  String get matchStatsStatBadPasses => 'Poor passes';

  @override
  String get matchStatsStatGoodPlays => 'Good plays';

  @override
  String get matchStatsStatBadPlays => 'Poor plays';

  @override
  String get matchStatsStatOwnGoals => 'Own goals';

  @override
  String get matchStatsStatGoalsConceded => 'Goals conceded';

  @override
  String get matchStatsStatShots => 'Shots';

  @override
  String get matchStatsStatSaves => 'Saves';

  @override
  String get matchStatsStatKeyPasses => 'Key passes';

  @override
  String get matchStatsStatBallRecoveries => 'Ball recoveries';

  @override
  String get matchStatsStatFouls => 'Fouls';

  @override
  String get matchStatsStatCantadas => 'Blunders';

  @override
  String get matchStatsStatYellowCards => 'Yellow cards';

  @override
  String get matchStatsStatRedCards => 'Red cards';

  @override
  String get matchStatsOurGoalChip => 'Goal for';

  @override
  String get matchStatsOwnGoalChip => 'Own goal';

  @override
  String get matchListLoading => 'Loading matches…';

  @override
  String get matchListEmptyStateTitle => 'No matches yet';

  @override
  String get matchListEmptyStateBody =>
      'Matches you create from a call-up will show up here. Pull down to refresh.';

  @override
  String get matchListCalendarTitle => 'Calendar';

  @override
  String matchListElapsedTime(String time) {
    return 'Time: $time';
  }

  @override
  String get matchListHintLineupStart => 'Tap to line up and start';

  @override
  String get matchListHintManageResume => 'Tap to manage or resume';

  @override
  String get matchListHintViewStats => 'Tap to view stats';

  @override
  String get matchLineupSquadTitle => 'Match squad';

  @override
  String get matchLineupStarters => 'Starters';

  @override
  String get matchLineupSubstitutes => 'Substitutes';

  @override
  String get matchLineupStarterTag => 'Starter';

  @override
  String get matchLineupSubstituteTag => 'Substitute';

  @override
  String get matchFieldSelectPlayerFirst => 'Select a player in the list first';

  @override
  String get matchFieldMaxPlayersExpulsionRule =>
      'You cannot have more players on the pitch. Each sent-off player must leave a free slot.';

  @override
  String get matchConvocationTableEmpty =>
      'No players called up for this match';

  @override
  String get matchDeletedSuccess => 'Match deleted successfully';

  @override
  String get matchEventLegacyActionRegistered => 'Logged action';

  @override
  String get matchNotifTimeFirst => 'First half';

  @override
  String get matchNotifTimeHalf => 'Half-time';

  @override
  String get matchNotifTimeSecond => 'Second half';

  @override
  String get matchNotifTimeEnd => 'Full time';

  @override
  String get matchNotifPlayerUnknown => 'Player';

  @override
  String matchNotifGoalByPlayer(String player, String team) {
    return 'Goal by $player ($team)';
  }

  @override
  String matchNotifGoalRivalOnly(String opponent) {
    return 'Goal by $opponent';
  }

  @override
  String matchNotifOwnGoalByPlayer(String player, String team) {
    return 'Own goal by $player ($team)';
  }

  @override
  String matchNotifCardYellowForTeam(String player, String team) {
    return 'Yellow card $player ($team)';
  }

  @override
  String matchNotifCardRedForTeam(String player, String team) {
    return 'Red card $player ($team)';
  }

  @override
  String matchNotifCardYellowRivalWithPlayer(String player, String opponent) {
    return 'Yellow card $player ($opponent)';
  }

  @override
  String matchNotifCardRedRivalWithPlayer(String player, String opponent) {
    return 'Red card $player ($opponent)';
  }

  @override
  String matchNotifCardYellowRivalOnly(String opponent) {
    return 'Yellow card ($opponent)';
  }

  @override
  String matchNotifCardRedRivalOnly(String opponent) {
    return 'Red card ($opponent)';
  }
}
