// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Mi Equipo';

  @override
  String get authWelcomeBack => 'Bienvenido de nuevo';

  @override
  String get authCreateAccount => 'Crea tu cuenta';

  @override
  String get authHaveAccountLogin => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get authNoAccountRegister => '¿No tienes cuenta? Regístrate';

  @override
  String get loginEmailLabel => 'Correo electrónico';

  @override
  String get loginEmailError => 'Introduce tu email';

  @override
  String get loginPasswordLabel => 'Contraseña';

  @override
  String get loginPasswordMinError => 'Mínimo 6 caracteres';

  @override
  String get loginSubmit => 'Iniciar sesión';

  @override
  String get loginForgotPassword => 'Olvidé mi contraseña';

  @override
  String get registerFullNameLabel => 'Nombre completo';

  @override
  String get registerNameError => 'Dinos tu nombre';

  @override
  String get registerEmailInvalid => 'Email inválido';

  @override
  String get registerSubmit => 'Crear cuenta';

  @override
  String get authCheckEmailTitle => 'Revisa tu correo';

  @override
  String get authUnderstand => 'Entendido';

  @override
  String authRegisterEmailConfirm(String email) {
    return 'Te hemos enviado un enlace a $email. Ábrelo para activar tu cuenta antes de iniciar sesión. Revisa también la carpeta de correo no deseado (spam).';
  }

  @override
  String get authRegisterEmailActive =>
      'Tu cuenta ya está activa. Revisa tu bandeja de entrada por si recibes un correo de verificación o bienvenida (incluido spam).';

  @override
  String get homeLogoutTooltip => 'Cerrar sesión';

  @override
  String get homeInvitations => 'Invitaciones';

  @override
  String get homeNewTeam => 'Nuevo equipo';

  @override
  String get homeLoadingTeams => 'Cargando tus equipos…';

  @override
  String get homeRetry => 'Reintentar';

  @override
  String get homeYourPanel => 'Tu panel';

  @override
  String get homeTeamCountOne =>
      'Tienes 1 equipo. Toca una tarjeta para abrirlo.';

  @override
  String homeTeamCountMany(int count) {
    return 'Tienes $count equipos. Toca una tarjeta para abrirlo.';
  }

  @override
  String get homeEmptyTitle => 'Aún no tienes equipos';

  @override
  String get homeEmptySubtitle =>
      'Crea tu primer equipo con el botón flotante o revisa si tienes invitaciones pendientes.';

  @override
  String get homeEmptyHintNewTeam => 'Nuevo equipo: datos básicos y escudo';

  @override
  String get homeEmptyHintInvitations =>
      'Invitaciones: únete a un equipo existente';

  @override
  String get languageSpanish => 'Español (ES)';

  @override
  String get languageEnglish => 'Inglés (EN)';

  @override
  String get languageFrench => 'Francés (FR)';

  @override
  String get languageItalian => 'Italiano (IT)';

  @override
  String get languageSelectorTooltip => 'Idioma de la aplicación';

  @override
  String get roleSuperAdmin => 'Superadmin';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get rolePlayer => 'Jugador';

  @override
  String get roleExternal => 'Externo';

  @override
  String get roleSpectator => 'Espectador';

  @override
  String get tableColumnPlayer => 'Jugador';

  @override
  String get tableColumnPhoto => 'Foto';

  @override
  String get tableColumnAttends => 'Asiste';

  @override
  String get tableColumnAbsent => 'Falta';

  @override
  String get convocationCallAll => 'Todos';

  @override
  String get convocationPlayerStatus => 'Estado';

  @override
  String get convocationEmptyRoster => 'No hay jugadores en la plantilla';

  @override
  String get convocationToggleHint =>
      'Puedes convocar a todos de una vez o tocar cada jugador para alternar Sí / No.';

  @override
  String get commonYes => 'Sí';

  @override
  String get commonNo => 'No';

  @override
  String get accessInviteSpectatorOnlyHint =>
      'Como administrador, solo puedes invitar espectadores.';

  @override
  String get accessInviteSend => 'Enviar invitación';

  @override
  String get accessInviteNeedAuth =>
      'Debes estar autenticado para enviar invitaciones';

  @override
  String get accessAdminOnlyInvite =>
      'Solo un administrador del equipo puede invitar o quitar accesos.';

  @override
  String get accessUsersWithAccess => 'Usuarios con acceso';

  @override
  String get accessListBlurb =>
      'Lista en vivo: se actualiza sola cuando alguien recibe o pierde acceso. Cada fila muestra nombre y correo (tabla perfiles) para identificar a la persona.';

  @override
  String get accessPeopleCountSingle => '1 persona';

  @override
  String accessPeopleCountMany(int count) {
    return '$count personas';
  }

  @override
  String get accessEmptyMembersTitle => 'Nadie más tiene acceso aún.';

  @override
  String get accessEmptyMembersHint =>
      'Invita por correo con el botón de abajo.';

  @override
  String get accessProfileNoName => 'Sin nombre en perfil';

  @override
  String get accessProfileNoEmail =>
      'Correo no disponible (revisa el perfil en la app)';

  @override
  String get accessNamePrefix => 'Nombre: ';

  @override
  String get accessEmailPrefix => 'Correo: ';

  @override
  String get accessRolePrefix => 'Rol: ';

  @override
  String get accessYou => 'Tú';

  @override
  String accessInviteSent(String email, String role) {
    return 'Invitación enviada a $email como $role.';
  }

  @override
  String get navMenuTooltip => 'Menú del equipo';

  @override
  String get navMyTeams => 'Mis equipos';

  @override
  String get navTeamHomeSubtitle => 'Inicio del equipo';

  @override
  String get navAttendance => 'Asistencia';

  @override
  String get navConvocation => 'Convocatoria';

  @override
  String get navMatch => 'Partido';

  @override
  String get navManagement => 'Gestión';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionConfirm => 'Confirmar';

  @override
  String get screenAttendance => 'Asistencia';

  @override
  String get screenConvocation => 'Convocatoria';

  @override
  String get screenConvocationGenerated => 'Convocatoria generada';

  @override
  String get screenMatches => 'Partidos';

  @override
  String get screenMatchLive => 'Partido en curso';

  @override
  String get screenMatchDetail => 'Detalle del partido';

  @override
  String get screenDeleteMatch => 'Eliminar partido';

  @override
  String get screenDeleteAttendance => 'Eliminar asistencia';

  @override
  String get screenTeamManagement => 'Gestión de equipo';

  @override
  String get screenTeamAccess => 'Acceso al equipo';

  @override
  String get screenRoster => 'Plantilla';

  @override
  String get screenSelectLocation => 'Seleccionar ubicación';

  @override
  String get screenNewTeamPage => 'Nuevo equipo';

  @override
  String get screenAddPlayer => 'Añadir jugador';

  @override
  String get screenEditPlayer => 'Editar jugador';

  @override
  String get shareImageTooltip => 'Compartir imagen';

  @override
  String convocationShareText(String teamName) {
    return 'Convocatoria de $teamName';
  }

  @override
  String get backToTeam => 'Volver al equipo';

  @override
  String get dialogNoAccessTitle => 'Sin acceso al equipo';

  @override
  String get dialogNoAccessBody =>
      'Ya no tienes acceso a este equipo. Se ha quitado de tu panel y no podrás volver a entrar hasta que un administrador te invite de nuevo.';

  @override
  String get dialogLeaveTeamTitle => 'Abandonar equipo';

  @override
  String leaveTeamPromptExternal(String teamName) {
    return '¿Quieres salir de $teamName? Dejarás de ver la plantilla y los partidos hasta que un administrador te vuelva a invitar.';
  }

  @override
  String leaveTeamPromptAdmin(String teamName) {
    return '¿Quieres abandonar $teamName como administrador? Perderás los permisos de gestión; solo podrás volver si un superadmin te invita de nuevo.';
  }

  @override
  String leaveTeamPromptPlayer(String teamName) {
    return '¿Quieres salir de $teamName como jugador? Dejarás de figurar en la plantilla hasta que te den de alta de nuevo.';
  }

  @override
  String leaveTeamPromptGeneric(String teamName) {
    return '¿Quieres salir de $teamName?';
  }

  @override
  String get leaveTeamButton => 'Salir del equipo';

  @override
  String get snackbarLeftTeam => 'Has salido del equipo';

  @override
  String get teamCheckingAccess => 'Comprobando acceso…';

  @override
  String get teamLoadingRoster => 'Cargando plantilla…';

  @override
  String get teamEmptyRosterTitle => 'Aún no hay jugadores en la plantilla';

  @override
  String get teamEmptyRosterHint =>
      'Añádelos desde Gestión → Modificar plantilla.';

  @override
  String get teamHeaderLeaveShort => 'Salir';

  @override
  String get teamPlayerCountOne => '1 jugador';

  @override
  String teamPlayerCountMany(int count) {
    return '$count jugadores';
  }

  @override
  String get teamMustLoginAddPlayers =>
      'Debes iniciar sesión para añadir jugadores';

  @override
  String get teamMustLoginEditPlayers =>
      'Debes iniciar sesión para editar jugadores';

  @override
  String get teamMustLoginDeletePlayers =>
      'Debes iniciar sesión para borrar jugadores';

  @override
  String get dialogDeletePlayerLead => '¿Seguro que quieres borrar a ';

  @override
  String get teamManagementLogoLabel => 'Escudo';

  @override
  String get teamManagementLogoTapHint => 'Toca para cambiar';

  @override
  String get teamManagementNameLabel => 'Nombre del equipo';

  @override
  String get teamManagementNameHint => 'Ej. CD Mi Equipo';

  @override
  String get accessDefaultUserName => 'Usuario';

  @override
  String get teamMgmtSectionTeamData => 'Datos del equipo';

  @override
  String get teamMgmtColorRowLabel => 'Color del equipo';

  @override
  String get teamMgmtColorPickTooltip => 'Toca para elegir color';

  @override
  String get teamMustLoginSaveChanges =>
      'Debes iniciar sesión para guardar cambios';

  @override
  String teamMgmtLogoUploadError(String message) {
    return 'Error subiendo logo: $message';
  }

  @override
  String get teamMgmtSaveSuccess => 'Cambios guardados correctamente';

  @override
  String get teamMgmtSectionRosterAccess => 'Plantilla y acceso';

  @override
  String get teamMgmtEditRosterTitle => 'Modificar plantilla';

  @override
  String get teamMgmtEditRosterSubtitle => 'Altas, bajas y datos de jugadores';

  @override
  String get teamMgmtAccessTitle => 'Administrar acceso';

  @override
  String get teamMgmtAccessSubtitle =>
      'Invitar admins o espectadores al equipo';

  @override
  String get teamImportPlayerTitle => 'Importar de otro equipo';

  @override
  String get teamImportPlayerSubtitle =>
      'Elige un equipo que gestiones y un jugador. Se copian nombre, contacto, foto y posiciones; las estadísticas en este equipo empiezan desde cero.';

  @override
  String get teamImportPlayerStatsHint =>
      'No se transfieren las estadísticas del equipo anterior.';

  @override
  String get teamImportPlayerButton => 'Importar de otro equipo';

  @override
  String get teamImportPlayerSelectTeam => 'Equipo de origen';

  @override
  String get teamImportPlayerNoSourceTeams =>
      'No tienes otro equipo donde seas administrador o superadministrador.';

  @override
  String get teamImportPlayerPickTeamFirst =>
      'Selecciona un equipo para ver su plantilla.';

  @override
  String get teamImportPlayerEmptyRoster =>
      'Esta plantilla no tiene jugadores.';

  @override
  String get teamImportPlayerConfirmTitle => 'Importar jugador';

  @override
  String teamImportPlayerConfirmBody(String playerName, String sourceTeamName) {
    return '¿Importar a $playerName desde $sourceTeamName a esta plantilla? Sus estadísticas aquí empiezan en cero.';
  }

  @override
  String get teamImportPlayerConfirmAction => 'Importar';

  @override
  String get teamImportPlayerSuccess => 'Jugador importado';

  @override
  String get teamMgmtSectionMaintenance => 'Mantenimiento de datos';

  @override
  String get teamMgmtDeleteMatchesTitle => 'Eliminar partidos';

  @override
  String get teamMgmtDeleteMatchesSubtitle =>
      'Quita partidos concretos del calendario';

  @override
  String get teamMgmtDeleteAttendanceTitle => 'Eliminar asistencias';

  @override
  String get teamMgmtDeleteAttendanceSubtitle =>
      'Borra días de control de asistencia';

  @override
  String get teamMgmtSectionCritical => 'Zona crítica';

  @override
  String get teamAccessLoadMembersError =>
      'No se han podido cargar los miembros del equipo';

  @override
  String get convSectionMatch => 'Partido';

  @override
  String get convRivalLabel => 'Rival';

  @override
  String get convVenueLabel => 'Sede';

  @override
  String get convHome => 'Casa';

  @override
  String get convAway => 'Fuera';

  @override
  String get convLocationHint => 'Lugar (opcional)';

  @override
  String get convLocationFieldHint =>
      'Pabellón o dirección · aparece en la imagen';

  @override
  String get matchFormation => 'Formación';

  @override
  String get matchDeleteEvent => 'Eliminar evento';

  @override
  String get matchConfirmAction => 'Confirmar acción';

  @override
  String get matchPickAssistant => 'Seleccionar asistente';

  @override
  String get matchNoAttendanceOption => 'Sin asistencia';

  @override
  String get matchEndGame => 'Terminar partido';

  @override
  String get matchMustLoginStart =>
      'Debes iniciar sesión para empezar el partido';

  @override
  String get matchStartedOk => 'Partido empezado correctamente';

  @override
  String get matchMustLoginPause =>
      'Debes iniciar sesión para pausar el partido';

  @override
  String get matchStateUpdateFail =>
      'No se ha podido actualizar el estado del partido';

  @override
  String get matchMustLoginResume =>
      'Debes iniciar sesión para reanudar el partido';

  @override
  String get matchMustLoginFinish =>
      'Debes iniciar sesión para terminar el partido';

  @override
  String get matchOpponentGoal => 'Gol en contra';

  @override
  String get matchDeleteEventQuestion =>
      '¿Eliminar este evento del partido? El marcador, las notas y la disciplina se recalcularán.';

  @override
  String get matchEventDeleted => 'Evento eliminado';

  @override
  String get matchEventDeleteFail => 'No se ha podido eliminar el evento';

  @override
  String get matchLoginRequiredShort => 'Debes iniciar sesión';

  @override
  String get matchActionRegisterLogin =>
      'Debes iniciar sesión para registrar acciones';

  @override
  String get matchActionRegisterFail => 'No se ha podido registrar la acción';

  @override
  String get matchActionRegisteredPrefix => 'Acción registrada para ';

  @override
  String get matchEndGameConfirm =>
      '¿Terminar el partido? Se guardará el resultado final.';

  @override
  String matchRegisterActionIntro(String label) {
    return '¿Seguro que quieres registrar \"$label\" para ';
  }

  @override
  String get dialogDeletePlayerTitle => 'Borrar jugador';

  @override
  String get dialogDeleteTeamTitle => 'Borrar equipo';

  @override
  String get dialogRevokeAccessTitle => 'Quitar acceso';

  @override
  String get dialogInviteUserTitle => 'Invitar usuario';

  @override
  String get accessRevokeBody =>
      '¿Seguro que quieres quitar el acceso a este usuario?';

  @override
  String get accessRevokeAction => 'Quitar';

  @override
  String get accessRevokedOk => 'Acceso eliminado correctamente';

  @override
  String get accessRevokeFail => 'No se ha podido quitar el acceso';

  @override
  String get accessCannotRemoveSuperAdmin =>
      'Solo el creador del equipo (superadmin) puede quitar a otro superadmin.';

  @override
  String get accessInviteRole => 'Rol';

  @override
  String get accessAdminOnlyRevoke =>
      'Solo un administrador del equipo puede quitar accesos.';

  @override
  String get teamColorDefault => 'Predeterminado (verde app)';

  @override
  String get teamColorSheetTitle => 'Color del equipo';

  @override
  String get teamColorSheetHint =>
      'Barra superior, botones y acentos dentro del equipo. Tarjetas y zonas suaves se tiñen con tu color (misma suavidad que el verde de la app). Vacío = verde por defecto.';

  @override
  String get teamSaveDataButton => 'Guardar datos del equipo';

  @override
  String get actionDelete => 'Borrar';

  @override
  String get actionRemove => 'Eliminar';

  @override
  String get teamDeletedSnackbar => 'Equipo borrado correctamente';

  @override
  String get matchDeleteNeedLogin =>
      'Debes iniciar sesión para borrar partidos';

  @override
  String matchDeleteConfirmBody(String opponent) {
    return '¿Seguro que quieres eliminar el partido contra $opponent?';
  }

  @override
  String get matchListLoadError => 'No se han podido cargar los partidos';

  @override
  String get matchStatsLoadError =>
      'No se han podido cargar los datos del partido';

  @override
  String get matchListEmpty => 'No hay partidos para este equipo';

  @override
  String get matchStatusPending => 'Pendiente';

  @override
  String get matchStatusFirstHalf => '1ª parte';

  @override
  String get matchStatusHalfTime => 'Descanso';

  @override
  String get matchStatusSecondHalf => '2ª parte';

  @override
  String get matchStatusFinished => 'Finalizado';

  @override
  String get matchLastEvent => 'Último evento';

  @override
  String get matchScoreAndTime => 'Marcador y tiempo';

  @override
  String get matchQuickScore => 'Marcador rápido';

  @override
  String get matchLiveStatsCardTitle => 'Estadísticas';

  @override
  String get matchShotsOnGoalSection => 'Tiros a puerta';

  @override
  String get matchEventRivalShot => 'Tiro a puerta (rival)';

  @override
  String get matchRivalShotAddTooltip => 'Más un tiro a puerta del rival';

  @override
  String get matchRivalShotRemoveTooltip => 'Menos un tiro a puerta del rival';

  @override
  String get matchNoRivalShotsToRemove =>
      'No hay tiros a puerta del rival que quitar';

  @override
  String get matchSpectatorCannotStart =>
      'Solo el cuerpo técnico puede iniciar el partido.';

  @override
  String get matchFoulsAndCornersSection => 'Faltas y córners';

  @override
  String get matchFoulsShort => 'Faltas';

  @override
  String get matchCornersShort => 'Córners';

  @override
  String get matchYellowCardsShort => 'Amarillas';

  @override
  String get matchRedCardsShort => 'Rojas';

  @override
  String get matchRivalYellowCardNote => 'Tarjeta amarilla (rival)';

  @override
  String get matchRivalRedCardNote => 'Tarjeta roja (rival)';

  @override
  String get matchCounterAddTooltip => 'Añadir uno';

  @override
  String get matchCounterRemoveTooltip => 'Quitar el último';

  @override
  String get matchNoCounterToRemove => 'No hay nada que quitar';

  @override
  String get matchActionLabelFoul => 'Falta';

  @override
  String get matchFieldAndFormation => 'Campo y formación';

  @override
  String get matchSquadTitle => 'Convocados';

  @override
  String get matchSquadHintSpectator =>
      'Modo espectador: la lista y el campo son solo informativos.';

  @override
  String get matchSquadHintCoach =>
      'Toca un jugador para seleccionarlo; toca el campo para alinear o abrir acciones.';

  @override
  String get matchPlayerSentOffCannotReturn =>
      'Jugador expulsado, no puede volver a entrar';

  @override
  String get matchEventsTitle => 'Eventos del partido';

  @override
  String get matchEventsHintSpectator => 'Cronología del encuentro.';

  @override
  String get matchEventsHintCoach =>
      'Toca un evento para eliminarlo. Solo los administradores del equipo pueden borrar eventos.';

  @override
  String get matchEventsEmpty => 'Aún no hay eventos registrados';

  @override
  String get matchStartGameButton => 'Empezar partido';

  @override
  String get matchResumeGameButton => 'Reanudar partido';

  @override
  String get matchHalfTimeButton => 'Descanso';

  @override
  String get matchPhaseNotStarted => 'Sin iniciar';

  @override
  String get matchSpectatorNoPlayerActions =>
      'Modo espectador: no puedes registrar acciones de jugadores';

  @override
  String get matchConfirmGoalTitle => 'Confirmar gol';

  @override
  String get matchConfirmAddGoalOur =>
      '¿Seguro que quieres añadir un gol a tu equipo?';

  @override
  String get matchConfirmAddGoalRival =>
      '¿Seguro que quieres registrar un gol en contra?';

  @override
  String get matchMustLoginRegisterGoals =>
      'Debes iniciar sesión para registrar goles';

  @override
  String get matchGoalsOurTeamFromField =>
      'Los goles de tu equipo se registran desde un jugador en el campo';

  @override
  String get matchOpponentGoalRegisteredOk =>
      'Gol en contra registrado correctamente';

  @override
  String get matchGoalSaveFail => 'No se ha podido registrar el gol';

  @override
  String get matchConvocationLoadError =>
      'No se ha podido cargar la convocatoria';

  @override
  String get matchFillAllPositionsBeforeStart =>
      'Debes colocar todos los jugadores antes de empezar el partido';

  @override
  String get matchConfirmStartTitle => 'Empezar partido';

  @override
  String get matchConfirmStartBody => '¿Seguro que quieres empezar el partido?';

  @override
  String get matchConfirmHalfTimeTitle => 'Ir al descanso';

  @override
  String get matchConfirmHalfTimeBody =>
      '¿Seguro que quieres pasar al descanso?';

  @override
  String get matchConfirmResumeTitle => 'Reanudar partido';

  @override
  String get matchConfirmResumeBody =>
      '¿Seguro que quieres empezar la 2ª parte?';

  @override
  String get matchEndGameDialogBody =>
      '¿Seguro que quieres terminar el partido? Se guardarán las estadísticas.';

  @override
  String get matchEndGameAction => 'Terminar';

  @override
  String get matchSentOffDoubleYellow => ' expulsado por doble amarilla';

  @override
  String get matchSentOffSimple => ' expulsado';

  @override
  String matchUnknownPlayerId(int id) {
    return 'Jugador $id';
  }

  @override
  String get matchLiveFormationRegistered => 'Formación registrada';

  @override
  String matchLiveFormationLine(String formation) {
    return 'Formación: $formation';
  }

  @override
  String get matchLiveSubstitutionEnters => 'Sustitución · Entra ';

  @override
  String get matchLiveSubstitutionLeaves => ' · Sale ';

  @override
  String get matchLiveSubstitutionToFreeSlot => ' (hueco libre / banquillo)';

  @override
  String get matchLiveMinuteSquad => 'Alineación';

  @override
  String get matchLivePeriodFallback => 'Cambio de periodo o estado';

  @override
  String get matchLiveGoalBy => 'Gol de ';

  @override
  String get matchLiveAssistOpening => ' (asistencia de ';

  @override
  String get matchLiveAssistClosing => ')';

  @override
  String get matchLiveConcededDefault => 'Gol en contra';

  @override
  String get matchLiveOwnGoal => 'Autogol · ';

  @override
  String get matchLiveYellowCard => 'Tarjeta amarilla: ';

  @override
  String get matchLiveRedCard => 'Tarjeta roja: ';

  @override
  String get matchLiveSaveBy => 'Parada de ';

  @override
  String matchLiveSaveWithNote(String note) {
    return 'Parada · $note';
  }

  @override
  String get matchLiveSaveOnly => 'Parada';

  @override
  String get matchLiveKeyPass => 'Pase clave: ';

  @override
  String get matchLiveGoodPass => 'Buen pase: ';

  @override
  String get matchLiveBadPass => 'Mal pase: ';

  @override
  String get matchLiveGoodPlay => 'Buena jugada: ';

  @override
  String get matchLiveBadPlay => 'Mala jugada: ';

  @override
  String get matchLiveBallRecovery => 'Balón recuperado: ';

  @override
  String get matchLiveGoodSave => 'Buena parada: ';

  @override
  String get matchLiveShot => 'Tiro: ';

  @override
  String get matchLiveFoul => 'Falta: ';

  @override
  String get matchLiveCantada => 'Cantada: ';

  @override
  String get matchLiveEvent => 'Evento';

  @override
  String matchLiveEventLine(String label, String note) {
    return '$label: $note';
  }

  @override
  String get matchNoteFirstHalfStart => 'Inicio 1ª parte';

  @override
  String get matchNoteSecondHalfStart => 'Inicio 2ª parte';

  @override
  String get matchNoteMatchFinished => 'Final del partido';

  @override
  String get matchActionLabelGoal => 'Gol';

  @override
  String get matchActionLabelGoodPass => 'Buen pase';

  @override
  String get matchActionLabelGoodPlay => 'Buena jugada';

  @override
  String get matchActionLabelBallRecovery => 'Balón recuperado';

  @override
  String get matchActionLabelShot => 'Tiro';

  @override
  String get matchActionLabelYellowCard => 'Tarjeta amarilla';

  @override
  String get matchActionLabelRedCard => 'Tarjeta roja';

  @override
  String get matchActionLabelBadPass => 'Mal pase';

  @override
  String get matchActionLabelBadPlay => 'Mala jugada';

  @override
  String get matchActionLabelKeyPass => 'Pase clave';

  @override
  String get matchActionLabelGoodSave => 'Buena parada';

  @override
  String get matchActionLabelCantada => 'Cantada';

  @override
  String get matchGoalRegisteredPrefix => 'Gol registrado para ';

  @override
  String get attendanceSaveHint =>
      'Marca ✓ (asiste) o X (falta) y guarda el día seleccionado.';

  @override
  String get attendanceSaveButton => 'Guardar asistencia';

  @override
  String get attendanceSaveNeedLogin =>
      'Debes iniciar sesión para guardar la asistencia';

  @override
  String get attendanceSaveTeamLoadError =>
      'No se ha podido cargar la plantilla del equipo';

  @override
  String get attendanceSaveInProgress => 'Guardando…';

  @override
  String get attendanceSaveSuccess => 'Asistencia guardada correctamente';

  @override
  String get convDatetimeSectionTitle => 'Fecha y horarios';

  @override
  String get convPickDateTooltip => 'Elegir fecha';

  @override
  String get tooltipChange => 'Cambiar';

  @override
  String get attendanceDeleteLoadError =>
      'No se han podido cargar los días de asistencia';

  @override
  String get attendanceDeleteEmpty =>
      'No hay días de entrenamiento registrados';

  @override
  String get attendanceDeleteNeedLogin =>
      'Debes iniciar sesión para borrar asistencia';

  @override
  String get teamDeleteNavTitle => 'Borrar equipo';

  @override
  String get teamDeleteNavSubtitle =>
      'Elimina el club y deja de verlo en inicio';

  @override
  String get teamDeleteNeedLogin =>
      'Debes iniciar sesión para borrar el equipo';

  @override
  String get teamDeleteConfirmBody =>
      '¿Seguro que quieres borrar este equipo? Esta acción no se puede deshacer.';

  @override
  String attendanceDeleteConfirmBody(String date) {
    return '¿Seguro que quieres eliminar la asistencia del $date?';
  }

  @override
  String get dialogClose => 'Cerrar';

  @override
  String get convocationNotesTitle => 'Observaciones';

  @override
  String get convocationNotesHint => 'Material, puntualidad, mensaje al grupo…';

  @override
  String get convocationSavedSuccess => 'Convocatoria guardada correctamente';

  @override
  String get convocationImageSectionMatchDetails => 'Detalles del partido';

  @override
  String get convocationImageLabelDate => 'Fecha';

  @override
  String get convocationImageLabelMatchTime => 'Hora del partido';

  @override
  String get convocationImageLabelCallTime => 'Hora convocatoria';

  @override
  String get convocationImageLabelVenue => 'Lugar';

  @override
  String get convocationImageSectionSquad => 'Jugadores convocados';

  @override
  String get convocationImageObservationsTitle => 'Observaciones';

  @override
  String get convocationImagePlayerFallback => 'Jugador';

  @override
  String matchSummaryVs(String opponent) {
    return 'vs $opponent';
  }

  @override
  String get matchVenueHome => 'Local';

  @override
  String get matchVenueAway => 'Visitante';

  @override
  String get matchScoreForLabel => 'A favor';

  @override
  String get matchScoreAgainstLabel => 'Encajados';

  @override
  String get matchStatsScoreFinal => 'Marcador final';

  @override
  String get matchStatsScoreLive => 'Marcador';

  @override
  String get matchStatsTeamNamePlaceholder => 'Equipo';

  @override
  String get matchStatsLoadingSummary => 'Cargando resumen del partido…';

  @override
  String get matchStatsSectionField => 'Alineación';

  @override
  String matchStatsFormationChip(String formation) {
    return 'Formación: $formation';
  }

  @override
  String get matchStatsFieldDispositionHint =>
      'Disposición de los once titulares según las posiciones guardadas.';

  @override
  String get matchStatsSectionTimeline => 'Cronología';

  @override
  String get matchStatsTimelineEmpty => 'No hay eventos registrados';

  @override
  String get matchStatsTimelineEmptyHint =>
      'Los goles, cambios y tarjetas aparecerán aquí cuando se registren en el partido.';

  @override
  String get matchStatsMinutesPlayed => 'Minutos jugados';

  @override
  String get matchStatsStatGoals => 'Goles';

  @override
  String get matchStatsStatAssists => 'Asistencias';

  @override
  String get matchStatsStatGoodPasses => 'Pases buenos';

  @override
  String get matchStatsStatBadPasses => 'Pases malos';

  @override
  String get matchStatsStatGoodPlays => 'Buenas jugadas';

  @override
  String get matchStatsStatBadPlays => 'Malas jugadas';

  @override
  String get matchStatsOurGoalChip => 'Gol a favor';

  @override
  String get matchStatsOwnGoalChip => 'Autogol';

  @override
  String get matchListLoading => 'Cargando partidos…';

  @override
  String get matchListEmptyStateTitle => 'Sin partidos todavía';

  @override
  String get matchListEmptyStateBody =>
      'Los partidos que crees desde la convocatoria aparecerán aquí. Desliza hacia abajo para actualizar.';

  @override
  String get matchListCalendarTitle => 'Calendario';

  @override
  String matchListElapsedTime(String time) {
    return 'Tiempo: $time';
  }

  @override
  String get matchListHintLineupStart => 'Pulsa para alinear y empezar';

  @override
  String get matchListHintManageResume => 'Pulsa para gestionar o reanudar';

  @override
  String get matchListHintViewStats => 'Pulsa para ver estadísticas';

  @override
  String get matchLineupSquadTitle => 'Plantilla del partido';

  @override
  String get matchLineupStarters => 'Titulares';

  @override
  String get matchLineupSubstitutes => 'Suplentes';

  @override
  String get matchLineupStarterTag => 'Titular';

  @override
  String get matchLineupSubstituteTag => 'Suplente';

  @override
  String get matchFieldSelectPlayerFirst =>
      'Selecciona primero un jugador en la lista';

  @override
  String get matchFieldMaxPlayersExpulsionRule =>
      'No puedes tener más jugadores en el campo. Por cada expulsado debe quedar un hueco libre.';

  @override
  String get matchConvocationTableEmpty =>
      'No hay jugadores convocados para este partido';

  @override
  String get matchDeletedSuccess => 'Partido eliminado correctamente';

  @override
  String get matchEventLegacyActionRegistered => 'Acción registrada';

  @override
  String get matchNotifTimeFirst => 'Primera parte';

  @override
  String get matchNotifTimeHalf => 'Descanso';

  @override
  String get matchNotifTimeSecond => 'Segunda parte';

  @override
  String get matchNotifTimeEnd => 'Fin del partido';

  @override
  String get matchNotifPlayerUnknown => 'Jugador';

  @override
  String matchNotifGoalByPlayer(String player, String team) {
    return 'Gol de $player ($team)';
  }

  @override
  String matchNotifGoalRivalOnly(String opponent) {
    return 'Gol de $opponent';
  }

  @override
  String matchNotifOwnGoalByPlayer(String player, String team) {
    return 'Gol en propia de $player ($team)';
  }

  @override
  String matchNotifCardYellowForTeam(String player, String team) {
    return 'Tarjeta amarilla $player ($team)';
  }

  @override
  String matchNotifCardRedForTeam(String player, String team) {
    return 'Tarjeta roja $player ($team)';
  }

  @override
  String matchNotifCardYellowRivalWithPlayer(String player, String opponent) {
    return 'Tarjeta amarilla $player ($opponent)';
  }

  @override
  String matchNotifCardRedRivalWithPlayer(String player, String opponent) {
    return 'Tarjeta roja $player ($opponent)';
  }

  @override
  String matchNotifCardYellowRivalOnly(String opponent) {
    return 'Tarjeta amarilla ($opponent)';
  }

  @override
  String matchNotifCardRedRivalOnly(String opponent) {
    return 'Tarjeta roja ($opponent)';
  }
}
