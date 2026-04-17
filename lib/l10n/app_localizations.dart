import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi Equipo'**
  String get appTitle;

  /// No description provided for @authWelcomeBack.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido de nuevo'**
  String get authWelcomeBack;

  /// No description provided for @authCreateAccount.
  ///
  /// In es, this message translates to:
  /// **'Crea tu cuenta'**
  String get authCreateAccount;

  /// No description provided for @authHaveAccountLogin.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? Inicia sesión'**
  String get authHaveAccountLogin;

  /// No description provided for @authNoAccountRegister.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? Regístrate'**
  String get authNoAccountRegister;

  /// No description provided for @loginEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get loginEmailLabel;

  /// No description provided for @loginEmailError.
  ///
  /// In es, this message translates to:
  /// **'Introduce tu email'**
  String get loginEmailError;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get loginPasswordLabel;

  /// No description provided for @loginPasswordMinError.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 6 caracteres'**
  String get loginPasswordMinError;

  /// No description provided for @loginSubmit.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get loginSubmit;

  /// No description provided for @loginForgotPassword.
  ///
  /// In es, this message translates to:
  /// **'Olvidé mi contraseña'**
  String get loginForgotPassword;

  /// No description provided for @registerFullNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get registerFullNameLabel;

  /// No description provided for @registerNameError.
  ///
  /// In es, this message translates to:
  /// **'Dinos tu nombre'**
  String get registerNameError;

  /// No description provided for @registerEmailInvalid.
  ///
  /// In es, this message translates to:
  /// **'Email inválido'**
  String get registerEmailInvalid;

  /// No description provided for @registerSubmit.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get registerSubmit;

  /// No description provided for @authCheckEmailTitle.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu correo'**
  String get authCheckEmailTitle;

  /// No description provided for @authUnderstand.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get authUnderstand;

  /// No description provided for @authRegisterEmailConfirm.
  ///
  /// In es, this message translates to:
  /// **'Te hemos enviado un enlace a {email}. Ábrelo para activar tu cuenta antes de iniciar sesión. Revisa también la carpeta de correo no deseado (spam).'**
  String authRegisterEmailConfirm(String email);

  /// No description provided for @authRegisterEmailActive.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta ya está activa. Revisa tu bandeja de entrada por si recibes un correo de verificación o bienvenida (incluido spam).'**
  String get authRegisterEmailActive;

  /// No description provided for @homeLogoutTooltip.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get homeLogoutTooltip;

  /// No description provided for @homeInvitations.
  ///
  /// In es, this message translates to:
  /// **'Invitaciones'**
  String get homeInvitations;

  /// No description provided for @homeNewTeam.
  ///
  /// In es, this message translates to:
  /// **'Nuevo equipo'**
  String get homeNewTeam;

  /// No description provided for @homeLoadingTeams.
  ///
  /// In es, this message translates to:
  /// **'Cargando tus equipos…'**
  String get homeLoadingTeams;

  /// No description provided for @homeRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get homeRetry;

  /// No description provided for @homeYourPanel.
  ///
  /// In es, this message translates to:
  /// **'Tu panel'**
  String get homeYourPanel;

  /// No description provided for @homeTeamCountOne.
  ///
  /// In es, this message translates to:
  /// **'Tienes 1 equipo. Toca una tarjeta para abrirlo.'**
  String get homeTeamCountOne;

  /// No description provided for @homeTeamCountMany.
  ///
  /// In es, this message translates to:
  /// **'Tienes {count} equipos. Toca una tarjeta para abrirlo.'**
  String homeTeamCountMany(int count);

  /// No description provided for @homeEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes equipos'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Crea tu primer equipo con el botón flotante o revisa si tienes invitaciones pendientes.'**
  String get homeEmptySubtitle;

  /// No description provided for @homeEmptyHintNewTeam.
  ///
  /// In es, this message translates to:
  /// **'Nuevo equipo: datos básicos y escudo'**
  String get homeEmptyHintNewTeam;

  /// No description provided for @homeEmptyHintInvitations.
  ///
  /// In es, this message translates to:
  /// **'Invitaciones: únete a un equipo existente'**
  String get homeEmptyHintInvitations;

  /// No description provided for @languageSpanish.
  ///
  /// In es, this message translates to:
  /// **'Español (ES)'**
  String get languageSpanish;

  /// No description provided for @languageEnglish.
  ///
  /// In es, this message translates to:
  /// **'Inglés (EN)'**
  String get languageEnglish;

  /// No description provided for @languageFrench.
  ///
  /// In es, this message translates to:
  /// **'Francés (FR)'**
  String get languageFrench;

  /// No description provided for @languageItalian.
  ///
  /// In es, this message translates to:
  /// **'Italiano (IT)'**
  String get languageItalian;

  /// No description provided for @languageSelectorTooltip.
  ///
  /// In es, this message translates to:
  /// **'Idioma de la aplicación'**
  String get languageSelectorTooltip;

  /// No description provided for @roleSuperAdmin.
  ///
  /// In es, this message translates to:
  /// **'Superadmin'**
  String get roleSuperAdmin;

  /// No description provided for @roleAdmin.
  ///
  /// In es, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @rolePlayer.
  ///
  /// In es, this message translates to:
  /// **'Jugador'**
  String get rolePlayer;

  /// No description provided for @roleExternal.
  ///
  /// In es, this message translates to:
  /// **'Externo'**
  String get roleExternal;

  /// No description provided for @roleSpectator.
  ///
  /// In es, this message translates to:
  /// **'Espectador'**
  String get roleSpectator;

  /// No description provided for @tableColumnPlayer.
  ///
  /// In es, this message translates to:
  /// **'Jugador'**
  String get tableColumnPlayer;

  /// No description provided for @tableColumnAttends.
  ///
  /// In es, this message translates to:
  /// **'Asiste'**
  String get tableColumnAttends;

  /// No description provided for @tableColumnAbsent.
  ///
  /// In es, this message translates to:
  /// **'Falta'**
  String get tableColumnAbsent;

  /// No description provided for @convocationCallAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get convocationCallAll;

  /// No description provided for @convocationPlayerStatus.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get convocationPlayerStatus;

  /// No description provided for @convocationEmptyRoster.
  ///
  /// In es, this message translates to:
  /// **'No hay jugadores en la plantilla'**
  String get convocationEmptyRoster;

  /// No description provided for @convocationToggleHint.
  ///
  /// In es, this message translates to:
  /// **'Puedes convocar a todos de una vez o tocar cada jugador para alternar Sí / No.'**
  String get convocationToggleHint;

  /// No description provided for @commonYes.
  ///
  /// In es, this message translates to:
  /// **'Sí'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In es, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @accessInviteSend.
  ///
  /// In es, this message translates to:
  /// **'Enviar invitación'**
  String get accessInviteSend;

  /// No description provided for @accessInviteNeedAuth.
  ///
  /// In es, this message translates to:
  /// **'Debes estar autenticado para enviar invitaciones'**
  String get accessInviteNeedAuth;

  /// No description provided for @accessAdminOnlyInvite.
  ///
  /// In es, this message translates to:
  /// **'Solo un administrador del equipo puede invitar o quitar accesos.'**
  String get accessAdminOnlyInvite;

  /// No description provided for @accessUsersWithAccess.
  ///
  /// In es, this message translates to:
  /// **'Usuarios con acceso'**
  String get accessUsersWithAccess;

  /// No description provided for @accessListBlurb.
  ///
  /// In es, this message translates to:
  /// **'Lista en vivo: se actualiza sola cuando alguien recibe o pierde acceso. Cada fila muestra nombre y correo (tabla perfiles) para identificar a la persona.'**
  String get accessListBlurb;

  /// No description provided for @accessPeopleCountSingle.
  ///
  /// In es, this message translates to:
  /// **'1 persona'**
  String get accessPeopleCountSingle;

  /// No description provided for @accessPeopleCountMany.
  ///
  /// In es, this message translates to:
  /// **'{count} personas'**
  String accessPeopleCountMany(int count);

  /// No description provided for @accessEmptyMembersTitle.
  ///
  /// In es, this message translates to:
  /// **'Nadie más tiene acceso aún.'**
  String get accessEmptyMembersTitle;

  /// No description provided for @accessEmptyMembersHint.
  ///
  /// In es, this message translates to:
  /// **'Invita por correo con el botón de abajo.'**
  String get accessEmptyMembersHint;

  /// No description provided for @accessProfileNoName.
  ///
  /// In es, this message translates to:
  /// **'Sin nombre en perfil'**
  String get accessProfileNoName;

  /// No description provided for @accessProfileNoEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo no disponible (revisa el perfil en la app)'**
  String get accessProfileNoEmail;

  /// No description provided for @accessNamePrefix.
  ///
  /// In es, this message translates to:
  /// **'Nombre: '**
  String get accessNamePrefix;

  /// No description provided for @accessEmailPrefix.
  ///
  /// In es, this message translates to:
  /// **'Correo: '**
  String get accessEmailPrefix;

  /// No description provided for @accessRolePrefix.
  ///
  /// In es, this message translates to:
  /// **'Rol: '**
  String get accessRolePrefix;

  /// No description provided for @accessYou.
  ///
  /// In es, this message translates to:
  /// **'Tú'**
  String get accessYou;

  /// No description provided for @accessInviteSent.
  ///
  /// In es, this message translates to:
  /// **'Invitación enviada a {email} como {role}.'**
  String accessInviteSent(String email, String role);

  /// No description provided for @navMenuTooltip.
  ///
  /// In es, this message translates to:
  /// **'Menú del equipo'**
  String get navMenuTooltip;

  /// No description provided for @navMyTeams.
  ///
  /// In es, this message translates to:
  /// **'Mis equipos'**
  String get navMyTeams;

  /// No description provided for @navTeamHomeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Inicio del equipo'**
  String get navTeamHomeSubtitle;

  /// No description provided for @navAttendance.
  ///
  /// In es, this message translates to:
  /// **'Asistencia'**
  String get navAttendance;

  /// No description provided for @navConvocation.
  ///
  /// In es, this message translates to:
  /// **'Convocatoria'**
  String get navConvocation;

  /// No description provided for @navMatch.
  ///
  /// In es, this message translates to:
  /// **'Partido'**
  String get navMatch;

  /// No description provided for @navManagement.
  ///
  /// In es, this message translates to:
  /// **'Gestión'**
  String get navManagement;

  /// No description provided for @actionCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get actionCancel;

  /// No description provided for @actionConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get actionConfirm;

  /// No description provided for @screenAttendance.
  ///
  /// In es, this message translates to:
  /// **'Asistencia'**
  String get screenAttendance;

  /// No description provided for @screenConvocation.
  ///
  /// In es, this message translates to:
  /// **'Convocatoria'**
  String get screenConvocation;

  /// No description provided for @screenConvocationGenerated.
  ///
  /// In es, this message translates to:
  /// **'Convocatoria generada'**
  String get screenConvocationGenerated;

  /// No description provided for @screenMatches.
  ///
  /// In es, this message translates to:
  /// **'Partidos'**
  String get screenMatches;

  /// No description provided for @screenMatchLive.
  ///
  /// In es, this message translates to:
  /// **'Partido en curso'**
  String get screenMatchLive;

  /// No description provided for @screenMatchDetail.
  ///
  /// In es, this message translates to:
  /// **'Detalle del partido'**
  String get screenMatchDetail;

  /// No description provided for @screenDeleteMatch.
  ///
  /// In es, this message translates to:
  /// **'Eliminar partido'**
  String get screenDeleteMatch;

  /// No description provided for @screenDeleteAttendance.
  ///
  /// In es, this message translates to:
  /// **'Eliminar asistencia'**
  String get screenDeleteAttendance;

  /// No description provided for @screenTeamManagement.
  ///
  /// In es, this message translates to:
  /// **'Gestión de equipo'**
  String get screenTeamManagement;

  /// No description provided for @screenTeamAccess.
  ///
  /// In es, this message translates to:
  /// **'Acceso al equipo'**
  String get screenTeamAccess;

  /// No description provided for @screenRoster.
  ///
  /// In es, this message translates to:
  /// **'Plantilla'**
  String get screenRoster;

  /// No description provided for @screenSelectLocation.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar ubicación'**
  String get screenSelectLocation;

  /// No description provided for @screenNewTeamPage.
  ///
  /// In es, this message translates to:
  /// **'Nuevo equipo'**
  String get screenNewTeamPage;

  /// No description provided for @screenAddPlayer.
  ///
  /// In es, this message translates to:
  /// **'Añadir jugador'**
  String get screenAddPlayer;

  /// No description provided for @screenEditPlayer.
  ///
  /// In es, this message translates to:
  /// **'Editar jugador'**
  String get screenEditPlayer;

  /// No description provided for @shareImageTooltip.
  ///
  /// In es, this message translates to:
  /// **'Compartir imagen'**
  String get shareImageTooltip;

  /// No description provided for @convocationShareText.
  ///
  /// In es, this message translates to:
  /// **'Convocatoria de {teamName}'**
  String convocationShareText(String teamName);

  /// No description provided for @backToTeam.
  ///
  /// In es, this message translates to:
  /// **'Volver al equipo'**
  String get backToTeam;

  /// No description provided for @dialogNoAccessTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin acceso al equipo'**
  String get dialogNoAccessTitle;

  /// No description provided for @dialogNoAccessBody.
  ///
  /// In es, this message translates to:
  /// **'Ya no tienes acceso a este equipo. Se ha quitado de tu panel y no podrás volver a entrar hasta que un administrador te invite de nuevo.'**
  String get dialogNoAccessBody;

  /// No description provided for @dialogLeaveTeamTitle.
  ///
  /// In es, this message translates to:
  /// **'Abandonar equipo'**
  String get dialogLeaveTeamTitle;

  /// No description provided for @leaveTeamPromptExternal.
  ///
  /// In es, this message translates to:
  /// **'¿Quieres salir de {teamName}? Dejarás de ver la plantilla y los partidos hasta que un administrador te vuelva a invitar.'**
  String leaveTeamPromptExternal(String teamName);

  /// No description provided for @leaveTeamPromptAdmin.
  ///
  /// In es, this message translates to:
  /// **'¿Quieres abandonar {teamName} como administrador? Perderás los permisos de gestión; solo podrás volver si un superadmin te invita de nuevo.'**
  String leaveTeamPromptAdmin(String teamName);

  /// No description provided for @leaveTeamPromptPlayer.
  ///
  /// In es, this message translates to:
  /// **'¿Quieres salir de {teamName} como jugador? Dejarás de figurar en la plantilla hasta que te den de alta de nuevo.'**
  String leaveTeamPromptPlayer(String teamName);

  /// No description provided for @leaveTeamPromptGeneric.
  ///
  /// In es, this message translates to:
  /// **'¿Quieres salir de {teamName}?'**
  String leaveTeamPromptGeneric(String teamName);

  /// No description provided for @leaveTeamButton.
  ///
  /// In es, this message translates to:
  /// **'Salir del equipo'**
  String get leaveTeamButton;

  /// No description provided for @snackbarLeftTeam.
  ///
  /// In es, this message translates to:
  /// **'Has salido del equipo'**
  String get snackbarLeftTeam;

  /// No description provided for @teamCheckingAccess.
  ///
  /// In es, this message translates to:
  /// **'Comprobando acceso…'**
  String get teamCheckingAccess;

  /// No description provided for @teamLoadingRoster.
  ///
  /// In es, this message translates to:
  /// **'Cargando plantilla…'**
  String get teamLoadingRoster;

  /// No description provided for @teamEmptyRosterTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay jugadores en la plantilla'**
  String get teamEmptyRosterTitle;

  /// No description provided for @teamEmptyRosterHint.
  ///
  /// In es, this message translates to:
  /// **'Añádelos desde Gestión → Modificar plantilla.'**
  String get teamEmptyRosterHint;

  /// No description provided for @teamHeaderLeaveShort.
  ///
  /// In es, this message translates to:
  /// **'Salir'**
  String get teamHeaderLeaveShort;

  /// No description provided for @teamPlayerCountOne.
  ///
  /// In es, this message translates to:
  /// **'1 jugador'**
  String get teamPlayerCountOne;

  /// No description provided for @teamPlayerCountMany.
  ///
  /// In es, this message translates to:
  /// **'{count} jugadores'**
  String teamPlayerCountMany(int count);

  /// No description provided for @teamMustLoginAddPlayers.
  ///
  /// In es, this message translates to:
  /// **'Debes iniciar sesión para añadir jugadores'**
  String get teamMustLoginAddPlayers;

  /// No description provided for @teamMustLoginEditPlayers.
  ///
  /// In es, this message translates to:
  /// **'Debes iniciar sesión para editar jugadores'**
  String get teamMustLoginEditPlayers;

  /// No description provided for @teamMustLoginDeletePlayers.
  ///
  /// In es, this message translates to:
  /// **'Debes iniciar sesión para borrar jugadores'**
  String get teamMustLoginDeletePlayers;

  /// No description provided for @dialogDeletePlayerLead.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres borrar a '**
  String get dialogDeletePlayerLead;

  /// No description provided for @teamManagementLogoLabel.
  ///
  /// In es, this message translates to:
  /// **'Escudo'**
  String get teamManagementLogoLabel;

  /// No description provided for @teamManagementLogoTapHint.
  ///
  /// In es, this message translates to:
  /// **'Toca para cambiar'**
  String get teamManagementLogoTapHint;

  /// No description provided for @teamManagementNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre del equipo'**
  String get teamManagementNameLabel;

  /// No description provided for @teamManagementNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. CD Mi Equipo'**
  String get teamManagementNameHint;

  /// No description provided for @accessDefaultUserName.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get accessDefaultUserName;

  /// No description provided for @teamMgmtSectionTeamData.
  ///
  /// In es, this message translates to:
  /// **'Datos del equipo'**
  String get teamMgmtSectionTeamData;

  /// No description provided for @teamMgmtColorRowLabel.
  ///
  /// In es, this message translates to:
  /// **'Color del equipo'**
  String get teamMgmtColorRowLabel;

  /// No description provided for @teamMgmtColorPickTooltip.
  ///
  /// In es, this message translates to:
  /// **'Toca para elegir color'**
  String get teamMgmtColorPickTooltip;

  /// No description provided for @teamMustLoginSaveChanges.
  ///
  /// In es, this message translates to:
  /// **'Debes iniciar sesión para guardar cambios'**
  String get teamMustLoginSaveChanges;

  /// No description provided for @teamMgmtLogoUploadError.
  ///
  /// In es, this message translates to:
  /// **'Error subiendo logo: {message}'**
  String teamMgmtLogoUploadError(String message);

  /// No description provided for @teamMgmtSaveSuccess.
  ///
  /// In es, this message translates to:
  /// **'Cambios guardados correctamente'**
  String get teamMgmtSaveSuccess;

  /// No description provided for @teamMgmtSectionRosterAccess.
  ///
  /// In es, this message translates to:
  /// **'Plantilla y acceso'**
  String get teamMgmtSectionRosterAccess;

  /// No description provided for @teamMgmtEditRosterTitle.
  ///
  /// In es, this message translates to:
  /// **'Modificar plantilla'**
  String get teamMgmtEditRosterTitle;

  /// No description provided for @teamMgmtEditRosterSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Altas, bajas y datos de jugadores'**
  String get teamMgmtEditRosterSubtitle;

  /// No description provided for @teamMgmtAccessTitle.
  ///
  /// In es, this message translates to:
  /// **'Administrar acceso'**
  String get teamMgmtAccessTitle;

  /// No description provided for @teamMgmtAccessSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Invitar admins o espectadores al equipo'**
  String get teamMgmtAccessSubtitle;

  /// No description provided for @teamMgmtSectionMaintenance.
  ///
  /// In es, this message translates to:
  /// **'Mantenimiento de datos'**
  String get teamMgmtSectionMaintenance;

  /// No description provided for @teamMgmtDeleteMatchesTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar partidos'**
  String get teamMgmtDeleteMatchesTitle;

  /// No description provided for @teamMgmtDeleteMatchesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Quita partidos concretos del calendario'**
  String get teamMgmtDeleteMatchesSubtitle;

  /// No description provided for @teamMgmtDeleteAttendanceTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar asistencias'**
  String get teamMgmtDeleteAttendanceTitle;

  /// No description provided for @teamMgmtDeleteAttendanceSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Borra días de control de asistencia'**
  String get teamMgmtDeleteAttendanceSubtitle;

  /// No description provided for @teamMgmtSectionCritical.
  ///
  /// In es, this message translates to:
  /// **'Zona crítica'**
  String get teamMgmtSectionCritical;

  /// No description provided for @teamAccessLoadMembersError.
  ///
  /// In es, this message translates to:
  /// **'No se han podido cargar los miembros del equipo'**
  String get teamAccessLoadMembersError;

  /// No description provided for @convSectionMatch.
  ///
  /// In es, this message translates to:
  /// **'Partido'**
  String get convSectionMatch;

  /// No description provided for @convRivalLabel.
  ///
  /// In es, this message translates to:
  /// **'Rival'**
  String get convRivalLabel;

  /// No description provided for @convVenueLabel.
  ///
  /// In es, this message translates to:
  /// **'Sede'**
  String get convVenueLabel;

  /// No description provided for @convHome.
  ///
  /// In es, this message translates to:
  /// **'Casa'**
  String get convHome;

  /// No description provided for @convAway.
  ///
  /// In es, this message translates to:
  /// **'Fuera'**
  String get convAway;

  /// No description provided for @convLocationHint.
  ///
  /// In es, this message translates to:
  /// **'Lugar (opcional)'**
  String get convLocationHint;

  /// No description provided for @convLocationFieldHint.
  ///
  /// In es, this message translates to:
  /// **'Pabellón o dirección · aparece en la imagen'**
  String get convLocationFieldHint;

  /// No description provided for @matchFormation.
  ///
  /// In es, this message translates to:
  /// **'Formación'**
  String get matchFormation;

  /// No description provided for @matchDeleteEvent.
  ///
  /// In es, this message translates to:
  /// **'Eliminar evento'**
  String get matchDeleteEvent;

  /// No description provided for @matchConfirmAction.
  ///
  /// In es, this message translates to:
  /// **'Confirmar acción'**
  String get matchConfirmAction;

  /// No description provided for @matchPickAssistant.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar asistente'**
  String get matchPickAssistant;

  /// No description provided for @matchNoAttendanceOption.
  ///
  /// In es, this message translates to:
  /// **'Sin asistencia'**
  String get matchNoAttendanceOption;

  /// No description provided for @matchEndGame.
  ///
  /// In es, this message translates to:
  /// **'Terminar partido'**
  String get matchEndGame;

  /// No description provided for @matchMustLoginStart.
  ///
  /// In es, this message translates to:
  /// **'Debes iniciar sesión para empezar el partido'**
  String get matchMustLoginStart;

  /// No description provided for @matchStartedOk.
  ///
  /// In es, this message translates to:
  /// **'Partido empezado correctamente'**
  String get matchStartedOk;

  /// No description provided for @matchMustLoginPause.
  ///
  /// In es, this message translates to:
  /// **'Debes iniciar sesión para pausar el partido'**
  String get matchMustLoginPause;

  /// No description provided for @matchStateUpdateFail.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido actualizar el estado del partido'**
  String get matchStateUpdateFail;

  /// No description provided for @matchMustLoginResume.
  ///
  /// In es, this message translates to:
  /// **'Debes iniciar sesión para reanudar el partido'**
  String get matchMustLoginResume;

  /// No description provided for @matchMustLoginFinish.
  ///
  /// In es, this message translates to:
  /// **'Debes iniciar sesión para terminar el partido'**
  String get matchMustLoginFinish;

  /// No description provided for @matchOpponentGoal.
  ///
  /// In es, this message translates to:
  /// **'Gol del rival'**
  String get matchOpponentGoal;

  /// No description provided for @matchSubtractOur.
  ///
  /// In es, this message translates to:
  /// **'− Nuestro'**
  String get matchSubtractOur;

  /// No description provided for @matchSubtractRival.
  ///
  /// In es, this message translates to:
  /// **'− Rival'**
  String get matchSubtractRival;

  /// No description provided for @matchDeleteEventQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar este evento del partido? El marcador, las notas y la disciplina se recalcularán.'**
  String get matchDeleteEventQuestion;

  /// No description provided for @matchEventDeleted.
  ///
  /// In es, this message translates to:
  /// **'Evento eliminado'**
  String get matchEventDeleted;

  /// No description provided for @matchEventDeleteFail.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido eliminar el evento'**
  String get matchEventDeleteFail;

  /// No description provided for @matchLoginRequiredShort.
  ///
  /// In es, this message translates to:
  /// **'Debes iniciar sesión'**
  String get matchLoginRequiredShort;

  /// No description provided for @matchActionRegisterLogin.
  ///
  /// In es, this message translates to:
  /// **'Debes iniciar sesión para registrar acciones'**
  String get matchActionRegisterLogin;

  /// No description provided for @matchActionRegisterFail.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido registrar la acción'**
  String get matchActionRegisterFail;

  /// No description provided for @matchActionRegisteredPrefix.
  ///
  /// In es, this message translates to:
  /// **'Acción registrada para '**
  String get matchActionRegisteredPrefix;

  /// No description provided for @matchEndGameConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Terminar el partido? Se guardará el resultado final.'**
  String get matchEndGameConfirm;

  /// No description provided for @matchRegisterActionIntro.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres registrar \"{label}\" para '**
  String matchRegisterActionIntro(String label);

  /// No description provided for @dialogDeletePlayerTitle.
  ///
  /// In es, this message translates to:
  /// **'Borrar jugador'**
  String get dialogDeletePlayerTitle;

  /// No description provided for @dialogDeleteTeamTitle.
  ///
  /// In es, this message translates to:
  /// **'Borrar equipo'**
  String get dialogDeleteTeamTitle;

  /// No description provided for @dialogRevokeAccessTitle.
  ///
  /// In es, this message translates to:
  /// **'Quitar acceso'**
  String get dialogRevokeAccessTitle;

  /// No description provided for @dialogInviteUserTitle.
  ///
  /// In es, this message translates to:
  /// **'Invitar usuario'**
  String get dialogInviteUserTitle;

  /// No description provided for @accessRevokeBody.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres quitar el acceso a este usuario?'**
  String get accessRevokeBody;

  /// No description provided for @accessRevokeAction.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get accessRevokeAction;

  /// No description provided for @accessRevokedOk.
  ///
  /// In es, this message translates to:
  /// **'Acceso eliminado correctamente'**
  String get accessRevokedOk;

  /// No description provided for @accessRevokeFail.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido quitar el acceso'**
  String get accessRevokeFail;

  /// No description provided for @accessCannotRemoveSuperAdmin.
  ///
  /// In es, this message translates to:
  /// **'Solo el creador del equipo (superadmin) puede quitar a otro superadmin.'**
  String get accessCannotRemoveSuperAdmin;

  /// No description provided for @accessInviteRole.
  ///
  /// In es, this message translates to:
  /// **'Rol'**
  String get accessInviteRole;

  /// No description provided for @accessAdminOnlyRevoke.
  ///
  /// In es, this message translates to:
  /// **'Solo un administrador del equipo puede quitar accesos.'**
  String get accessAdminOnlyRevoke;

  /// No description provided for @teamColorDefault.
  ///
  /// In es, this message translates to:
  /// **'Predeterminado (verde app)'**
  String get teamColorDefault;

  /// No description provided for @teamColorSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Color del equipo'**
  String get teamColorSheetTitle;

  /// No description provided for @teamColorSheetHint.
  ///
  /// In es, this message translates to:
  /// **'Barra superior, botones y acentos dentro del equipo. Tarjetas y zonas suaves se tiñen con tu color (misma suavidad que el verde de la app). Vacío = verde por defecto.'**
  String get teamColorSheetHint;

  /// No description provided for @teamSaveDataButton.
  ///
  /// In es, this message translates to:
  /// **'Guardar datos del equipo'**
  String get teamSaveDataButton;

  /// No description provided for @actionDelete.
  ///
  /// In es, this message translates to:
  /// **'Borrar'**
  String get actionDelete;

  /// No description provided for @actionRemove.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get actionRemove;

  /// No description provided for @teamDeletedSnackbar.
  ///
  /// In es, this message translates to:
  /// **'Equipo borrado correctamente'**
  String get teamDeletedSnackbar;

  /// No description provided for @matchDeleteNeedLogin.
  ///
  /// In es, this message translates to:
  /// **'Debes iniciar sesión para borrar partidos'**
  String get matchDeleteNeedLogin;

  /// No description provided for @matchDeleteConfirmBody.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres eliminar el partido contra {opponent}?'**
  String matchDeleteConfirmBody(String opponent);

  /// No description provided for @matchListLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se han podido cargar los partidos'**
  String get matchListLoadError;

  /// No description provided for @matchStatsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se han podido cargar los datos del partido'**
  String get matchStatsLoadError;

  /// No description provided for @matchListEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay partidos para este equipo'**
  String get matchListEmpty;

  /// No description provided for @matchStatusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get matchStatusPending;

  /// No description provided for @matchStatusFirstHalf.
  ///
  /// In es, this message translates to:
  /// **'1ª parte'**
  String get matchStatusFirstHalf;

  /// No description provided for @matchStatusHalfTime.
  ///
  /// In es, this message translates to:
  /// **'Descanso'**
  String get matchStatusHalfTime;

  /// No description provided for @matchStatusSecondHalf.
  ///
  /// In es, this message translates to:
  /// **'2ª parte'**
  String get matchStatusSecondHalf;

  /// No description provided for @matchStatusFinished.
  ///
  /// In es, this message translates to:
  /// **'Finalizado'**
  String get matchStatusFinished;

  /// No description provided for @matchLastEvent.
  ///
  /// In es, this message translates to:
  /// **'Último evento'**
  String get matchLastEvent;

  /// No description provided for @matchScoreAndTime.
  ///
  /// In es, this message translates to:
  /// **'Marcador y tiempo'**
  String get matchScoreAndTime;

  /// No description provided for @matchQuickScore.
  ///
  /// In es, this message translates to:
  /// **'Marcador rápido'**
  String get matchQuickScore;

  /// No description provided for @matchGoalsFromFieldHint.
  ///
  /// In es, this message translates to:
  /// **'Los goles a favor se registran desde el campo (jugador) o las acciones.'**
  String get matchGoalsFromFieldHint;

  /// No description provided for @matchFieldAndFormation.
  ///
  /// In es, this message translates to:
  /// **'Campo y formación'**
  String get matchFieldAndFormation;

  /// No description provided for @matchSquadTitle.
  ///
  /// In es, this message translates to:
  /// **'Convocados'**
  String get matchSquadTitle;

  /// No description provided for @matchSquadHintSpectator.
  ///
  /// In es, this message translates to:
  /// **'Modo espectador: la lista y el campo son solo informativos.'**
  String get matchSquadHintSpectator;

  /// No description provided for @matchSquadHintCoach.
  ///
  /// In es, this message translates to:
  /// **'Toca un jugador para seleccionarlo; toca el campo para alinear o abrir acciones.'**
  String get matchSquadHintCoach;

  /// No description provided for @matchPlayerSentOffCannotReturn.
  ///
  /// In es, this message translates to:
  /// **'Jugador expulsado, no puede volver a entrar'**
  String get matchPlayerSentOffCannotReturn;

  /// No description provided for @matchEventsTitle.
  ///
  /// In es, this message translates to:
  /// **'Eventos del partido'**
  String get matchEventsTitle;

  /// No description provided for @matchEventsHintSpectator.
  ///
  /// In es, this message translates to:
  /// **'Cronología del encuentro.'**
  String get matchEventsHintSpectator;

  /// No description provided for @matchEventsHintCoach.
  ///
  /// In es, this message translates to:
  /// **'Toca un evento para eliminarlo. Solo los administradores del equipo pueden borrar eventos.'**
  String get matchEventsHintCoach;

  /// No description provided for @matchEventsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay eventos registrados'**
  String get matchEventsEmpty;

  /// No description provided for @matchStartGameButton.
  ///
  /// In es, this message translates to:
  /// **'Empezar partido'**
  String get matchStartGameButton;

  /// No description provided for @matchResumeGameButton.
  ///
  /// In es, this message translates to:
  /// **'Reanudar partido'**
  String get matchResumeGameButton;

  /// No description provided for @matchHalfTimeButton.
  ///
  /// In es, this message translates to:
  /// **'Descanso'**
  String get matchHalfTimeButton;

  /// No description provided for @matchPhaseNotStarted.
  ///
  /// In es, this message translates to:
  /// **'Sin iniciar'**
  String get matchPhaseNotStarted;

  /// No description provided for @matchSpectatorNoPlayerActions.
  ///
  /// In es, this message translates to:
  /// **'Modo espectador: no puedes registrar acciones de jugadores'**
  String get matchSpectatorNoPlayerActions;

  /// No description provided for @matchConfirmGoalTitle.
  ///
  /// In es, this message translates to:
  /// **'Confirmar gol'**
  String get matchConfirmGoalTitle;

  /// No description provided for @matchConfirmAddGoalOur.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres añadir un gol a tu equipo?'**
  String get matchConfirmAddGoalOur;

  /// No description provided for @matchConfirmAddGoalRival.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres añadir un gol al rival?'**
  String get matchConfirmAddGoalRival;

  /// No description provided for @matchMustLoginRegisterGoals.
  ///
  /// In es, this message translates to:
  /// **'Debes iniciar sesión para registrar goles'**
  String get matchMustLoginRegisterGoals;

  /// No description provided for @matchGoalsOurTeamFromField.
  ///
  /// In es, this message translates to:
  /// **'Los goles de tu equipo se registran desde un jugador en el campo'**
  String get matchGoalsOurTeamFromField;

  /// No description provided for @matchOpponentGoalRegisteredOk.
  ///
  /// In es, this message translates to:
  /// **'Gol del rival registrado correctamente'**
  String get matchOpponentGoalRegisteredOk;

  /// No description provided for @matchGoalSaveFail.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido registrar el gol'**
  String get matchGoalSaveFail;

  /// No description provided for @matchRemoveGoalTitle.
  ///
  /// In es, this message translates to:
  /// **'Quitar gol'**
  String get matchRemoveGoalTitle;

  /// No description provided for @matchConfirmRemoveGoalOur.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres quitar un gol a tu equipo?'**
  String get matchConfirmRemoveGoalOur;

  /// No description provided for @matchConfirmRemoveGoalRival.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres quitar un gol al rival?'**
  String get matchConfirmRemoveGoalRival;

  /// No description provided for @matchMustLoginRemoveGoals.
  ///
  /// In es, this message translates to:
  /// **'Debes iniciar sesión para quitar goles'**
  String get matchMustLoginRemoveGoals;

  /// No description provided for @matchNoGoalsToRemove.
  ///
  /// In es, this message translates to:
  /// **'No hay goles que quitar'**
  String get matchNoGoalsToRemove;

  /// No description provided for @matchGoalNotFoundInDb.
  ///
  /// In es, this message translates to:
  /// **'No se ha encontrado el gol en la base de datos'**
  String get matchGoalNotFoundInDb;

  /// No description provided for @matchGoalRemovedOk.
  ///
  /// In es, this message translates to:
  /// **'Gol eliminado correctamente'**
  String get matchGoalRemovedOk;

  /// No description provided for @matchGoalRemoveFail.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido quitar el gol'**
  String get matchGoalRemoveFail;

  /// No description provided for @matchConvocationLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido cargar la convocatoria'**
  String get matchConvocationLoadError;

  /// No description provided for @matchFillAllPositionsBeforeStart.
  ///
  /// In es, this message translates to:
  /// **'Debes colocar todos los jugadores antes de empezar el partido'**
  String get matchFillAllPositionsBeforeStart;

  /// No description provided for @matchConfirmStartTitle.
  ///
  /// In es, this message translates to:
  /// **'Empezar partido'**
  String get matchConfirmStartTitle;

  /// No description provided for @matchConfirmStartBody.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres empezar el partido?'**
  String get matchConfirmStartBody;

  /// No description provided for @matchConfirmHalfTimeTitle.
  ///
  /// In es, this message translates to:
  /// **'Ir al descanso'**
  String get matchConfirmHalfTimeTitle;

  /// No description provided for @matchConfirmHalfTimeBody.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres pasar al descanso?'**
  String get matchConfirmHalfTimeBody;

  /// No description provided for @matchConfirmResumeTitle.
  ///
  /// In es, this message translates to:
  /// **'Reanudar partido'**
  String get matchConfirmResumeTitle;

  /// No description provided for @matchConfirmResumeBody.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres empezar la 2ª parte?'**
  String get matchConfirmResumeBody;

  /// No description provided for @matchEndGameDialogBody.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres terminar el partido? Se guardarán las estadísticas.'**
  String get matchEndGameDialogBody;

  /// No description provided for @matchEndGameAction.
  ///
  /// In es, this message translates to:
  /// **'Terminar'**
  String get matchEndGameAction;

  /// No description provided for @matchSentOffDoubleYellow.
  ///
  /// In es, this message translates to:
  /// **' expulsado por doble amarilla'**
  String get matchSentOffDoubleYellow;

  /// No description provided for @matchSentOffSimple.
  ///
  /// In es, this message translates to:
  /// **' expulsado'**
  String get matchSentOffSimple;

  /// No description provided for @matchUnknownPlayerId.
  ///
  /// In es, this message translates to:
  /// **'Jugador {id}'**
  String matchUnknownPlayerId(int id);

  /// No description provided for @matchLiveFormationRegistered.
  ///
  /// In es, this message translates to:
  /// **'Formación registrada'**
  String get matchLiveFormationRegistered;

  /// No description provided for @matchLiveFormationLine.
  ///
  /// In es, this message translates to:
  /// **'Formación: {formation}'**
  String matchLiveFormationLine(String formation);

  /// No description provided for @matchLiveSubstitutionEnters.
  ///
  /// In es, this message translates to:
  /// **'Sustitución · Entra '**
  String get matchLiveSubstitutionEnters;

  /// No description provided for @matchLiveSubstitutionLeaves.
  ///
  /// In es, this message translates to:
  /// **' · Sale '**
  String get matchLiveSubstitutionLeaves;

  /// No description provided for @matchLivePeriodFallback.
  ///
  /// In es, this message translates to:
  /// **'Cambio de periodo o estado'**
  String get matchLivePeriodFallback;

  /// No description provided for @matchLiveGoalBy.
  ///
  /// In es, this message translates to:
  /// **'Gol de '**
  String get matchLiveGoalBy;

  /// No description provided for @matchLiveAssistOpening.
  ///
  /// In es, this message translates to:
  /// **' (asistencia de '**
  String get matchLiveAssistOpening;

  /// No description provided for @matchLiveAssistClosing.
  ///
  /// In es, this message translates to:
  /// **')'**
  String get matchLiveAssistClosing;

  /// No description provided for @matchLiveConcededDefault.
  ///
  /// In es, this message translates to:
  /// **'Gol en contra'**
  String get matchLiveConcededDefault;

  /// No description provided for @matchLiveOwnGoal.
  ///
  /// In es, this message translates to:
  /// **'Autogol · '**
  String get matchLiveOwnGoal;

  /// No description provided for @matchLiveYellowCard.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta amarilla: '**
  String get matchLiveYellowCard;

  /// No description provided for @matchLiveRedCard.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta roja: '**
  String get matchLiveRedCard;

  /// No description provided for @matchLiveSaveBy.
  ///
  /// In es, this message translates to:
  /// **'Parada de '**
  String get matchLiveSaveBy;

  /// No description provided for @matchLiveSaveWithNote.
  ///
  /// In es, this message translates to:
  /// **'Parada · {note}'**
  String matchLiveSaveWithNote(String note);

  /// No description provided for @matchLiveSaveOnly.
  ///
  /// In es, this message translates to:
  /// **'Parada'**
  String get matchLiveSaveOnly;

  /// No description provided for @matchLiveKeyPass.
  ///
  /// In es, this message translates to:
  /// **'Pase clave: '**
  String get matchLiveKeyPass;

  /// No description provided for @matchLiveGoodPass.
  ///
  /// In es, this message translates to:
  /// **'Buen pase: '**
  String get matchLiveGoodPass;

  /// No description provided for @matchLiveBadPass.
  ///
  /// In es, this message translates to:
  /// **'Pase impreciso: '**
  String get matchLiveBadPass;

  /// No description provided for @matchLiveGoodPlay.
  ///
  /// In es, this message translates to:
  /// **'Buena jugada: '**
  String get matchLiveGoodPlay;

  /// No description provided for @matchLiveBadPlay.
  ///
  /// In es, this message translates to:
  /// **'Jugada imprecisa: '**
  String get matchLiveBadPlay;

  /// No description provided for @matchLiveBallRecovery.
  ///
  /// In es, this message translates to:
  /// **'Balón recuperado: '**
  String get matchLiveBallRecovery;

  /// No description provided for @matchLiveEvent.
  ///
  /// In es, this message translates to:
  /// **'Evento'**
  String get matchLiveEvent;

  /// No description provided for @matchLiveEventLine.
  ///
  /// In es, this message translates to:
  /// **'{label}: {note}'**
  String matchLiveEventLine(String label, String note);

  /// No description provided for @matchNoteFirstHalfStart.
  ///
  /// In es, this message translates to:
  /// **'Inicio 1ª parte'**
  String get matchNoteFirstHalfStart;

  /// No description provided for @matchNoteSecondHalfStart.
  ///
  /// In es, this message translates to:
  /// **'Inicio 2ª parte'**
  String get matchNoteSecondHalfStart;

  /// No description provided for @matchNoteMatchFinished.
  ///
  /// In es, this message translates to:
  /// **'Final del partido'**
  String get matchNoteMatchFinished;

  /// No description provided for @matchActionLabelGoal.
  ///
  /// In es, this message translates to:
  /// **'Gol'**
  String get matchActionLabelGoal;

  /// No description provided for @matchActionLabelGoodPass.
  ///
  /// In es, this message translates to:
  /// **'Buen pase'**
  String get matchActionLabelGoodPass;

  /// No description provided for @matchActionLabelGoodPlay.
  ///
  /// In es, this message translates to:
  /// **'Buena jugada'**
  String get matchActionLabelGoodPlay;

  /// No description provided for @matchActionLabelBallRecovery.
  ///
  /// In es, this message translates to:
  /// **'Balón recuperado'**
  String get matchActionLabelBallRecovery;

  /// No description provided for @matchActionLabelYellowCard.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta amarilla'**
  String get matchActionLabelYellowCard;

  /// No description provided for @matchActionLabelRedCard.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta roja'**
  String get matchActionLabelRedCard;

  /// No description provided for @matchActionLabelBadPass.
  ///
  /// In es, this message translates to:
  /// **'Pase impreciso'**
  String get matchActionLabelBadPass;

  /// No description provided for @matchActionLabelBadPlay.
  ///
  /// In es, this message translates to:
  /// **'Jugada imprecisa'**
  String get matchActionLabelBadPlay;

  /// No description provided for @matchActionLabelKeyPass.
  ///
  /// In es, this message translates to:
  /// **'Pase clave'**
  String get matchActionLabelKeyPass;

  /// No description provided for @matchGoalRegisteredPrefix.
  ///
  /// In es, this message translates to:
  /// **'Gol registrado para '**
  String get matchGoalRegisteredPrefix;

  /// No description provided for @attendanceSaveHint.
  ///
  /// In es, this message translates to:
  /// **'Marca ✓ (asiste) o X (falta) y guarda el día seleccionado.'**
  String get attendanceSaveHint;

  /// No description provided for @attendanceSaveButton.
  ///
  /// In es, this message translates to:
  /// **'Guardar asistencia'**
  String get attendanceSaveButton;

  /// No description provided for @attendanceSaveNeedLogin.
  ///
  /// In es, this message translates to:
  /// **'Debes iniciar sesión para guardar la asistencia'**
  String get attendanceSaveNeedLogin;

  /// No description provided for @attendanceSaveTeamLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido cargar la plantilla del equipo'**
  String get attendanceSaveTeamLoadError;

  /// No description provided for @attendanceSaveInProgress.
  ///
  /// In es, this message translates to:
  /// **'Guardando…'**
  String get attendanceSaveInProgress;

  /// No description provided for @attendanceSaveSuccess.
  ///
  /// In es, this message translates to:
  /// **'Asistencia guardada correctamente'**
  String get attendanceSaveSuccess;

  /// No description provided for @convDatetimeSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Fecha y horarios'**
  String get convDatetimeSectionTitle;

  /// No description provided for @convPickDateTooltip.
  ///
  /// In es, this message translates to:
  /// **'Elegir fecha'**
  String get convPickDateTooltip;

  /// No description provided for @tooltipChange.
  ///
  /// In es, this message translates to:
  /// **'Cambiar'**
  String get tooltipChange;

  /// No description provided for @attendanceDeleteLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se han podido cargar los días de asistencia'**
  String get attendanceDeleteLoadError;

  /// No description provided for @attendanceDeleteEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay días de entrenamiento registrados'**
  String get attendanceDeleteEmpty;

  /// No description provided for @attendanceDeleteNeedLogin.
  ///
  /// In es, this message translates to:
  /// **'Debes iniciar sesión para borrar asistencia'**
  String get attendanceDeleteNeedLogin;

  /// No description provided for @teamDeleteNavTitle.
  ///
  /// In es, this message translates to:
  /// **'Borrar equipo'**
  String get teamDeleteNavTitle;

  /// No description provided for @teamDeleteNavSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Elimina el club y deja de verlo en inicio'**
  String get teamDeleteNavSubtitle;

  /// No description provided for @teamDeleteNeedLogin.
  ///
  /// In es, this message translates to:
  /// **'Debes iniciar sesión para borrar el equipo'**
  String get teamDeleteNeedLogin;

  /// No description provided for @teamDeleteConfirmBody.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres borrar este equipo? Esta acción no se puede deshacer.'**
  String get teamDeleteConfirmBody;

  /// No description provided for @attendanceDeleteConfirmBody.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres eliminar la asistencia del {date}?'**
  String attendanceDeleteConfirmBody(String date);

  /// No description provided for @dialogClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get dialogClose;

  /// No description provided for @convocationNotesTitle.
  ///
  /// In es, this message translates to:
  /// **'Observaciones'**
  String get convocationNotesTitle;

  /// No description provided for @convocationNotesHint.
  ///
  /// In es, this message translates to:
  /// **'Material, puntualidad, mensaje al grupo…'**
  String get convocationNotesHint;

  /// No description provided for @convocationSavedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Convocatoria guardada correctamente'**
  String get convocationSavedSuccess;

  /// No description provided for @convocationImageSectionMatchDetails.
  ///
  /// In es, this message translates to:
  /// **'Detalles del partido'**
  String get convocationImageSectionMatchDetails;

  /// No description provided for @convocationImageLabelDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get convocationImageLabelDate;

  /// No description provided for @convocationImageLabelMatchTime.
  ///
  /// In es, this message translates to:
  /// **'Hora del partido'**
  String get convocationImageLabelMatchTime;

  /// No description provided for @convocationImageLabelCallTime.
  ///
  /// In es, this message translates to:
  /// **'Hora convocatoria'**
  String get convocationImageLabelCallTime;

  /// No description provided for @convocationImageLabelVenue.
  ///
  /// In es, this message translates to:
  /// **'Lugar'**
  String get convocationImageLabelVenue;

  /// No description provided for @convocationImageSectionSquad.
  ///
  /// In es, this message translates to:
  /// **'Jugadores convocados'**
  String get convocationImageSectionSquad;

  /// No description provided for @convocationImageObservationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Observaciones'**
  String get convocationImageObservationsTitle;

  /// No description provided for @convocationImagePlayerFallback.
  ///
  /// In es, this message translates to:
  /// **'Jugador'**
  String get convocationImagePlayerFallback;

  /// No description provided for @convocationImageSectionMatchDetailsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Fecha, horas y lugar — léelo con calma'**
  String get convocationImageSectionMatchDetailsSubtitle;

  /// No description provided for @convocationImageLabelMatchKickoff.
  ///
  /// In es, this message translates to:
  /// **'HORA DEL PARTIDO (INICIO)'**
  String get convocationImageLabelMatchKickoff;

  /// No description provided for @convocationImageLabelCallArrival.
  ///
  /// In es, this message translates to:
  /// **'HORA DE CONVOCATORIA (LLEGADA)'**
  String get convocationImageLabelCallArrival;

  /// No description provided for @convocationImageCallTimeReminder.
  ///
  /// In es, this message translates to:
  /// **'Importante: debes llegar antes de esta hora, no cuando empiece el partido.'**
  String get convocationImageCallTimeReminder;

  /// No description provided for @convocationImageMapLinkIntro.
  ///
  /// In es, this message translates to:
  /// **'En el móvil puedes abrir este enlace para ver el sitio en el mapa:'**
  String get convocationImageMapLinkIntro;

  /// No description provided for @convocationImagePlaceHomeHeadline.
  ///
  /// In es, this message translates to:
  /// **'PARTIDO EN CASA'**
  String get convocationImagePlaceHomeHeadline;

  /// No description provided for @convocationImagePlaceHomeDetail.
  ///
  /// In es, this message translates to:
  /// **'Jugamos en nuestro campo.'**
  String get convocationImagePlaceHomeDetail;

  /// No description provided for @convocationImagePlaceAwayHeadline.
  ///
  /// In es, this message translates to:
  /// **'PARTIDO FUERA DE CASA'**
  String get convocationImagePlaceAwayHeadline;

  /// No description provided for @convocationImagePlaceAwayNoAddressDetail.
  ///
  /// In es, this message translates to:
  /// **'La dirección exacta la confirma el club. Pregunta a tu entrenador.'**
  String get convocationImagePlaceAwayNoAddressDetail;

  /// No description provided for @matchSummaryVs.
  ///
  /// In es, this message translates to:
  /// **'vs {opponent}'**
  String matchSummaryVs(String opponent);

  /// No description provided for @matchVenueHome.
  ///
  /// In es, this message translates to:
  /// **'Local'**
  String get matchVenueHome;

  /// No description provided for @matchVenueAway.
  ///
  /// In es, this message translates to:
  /// **'Visitante'**
  String get matchVenueAway;

  /// No description provided for @matchScoreForLabel.
  ///
  /// In es, this message translates to:
  /// **'A favor'**
  String get matchScoreForLabel;

  /// No description provided for @matchScoreAgainstLabel.
  ///
  /// In es, this message translates to:
  /// **'Encajados'**
  String get matchScoreAgainstLabel;

  /// No description provided for @matchStatsScoreFinal.
  ///
  /// In es, this message translates to:
  /// **'Marcador final'**
  String get matchStatsScoreFinal;

  /// No description provided for @matchStatsScoreLive.
  ///
  /// In es, this message translates to:
  /// **'Marcador'**
  String get matchStatsScoreLive;

  /// No description provided for @matchStatsLoadingSummary.
  ///
  /// In es, this message translates to:
  /// **'Cargando resumen del partido…'**
  String get matchStatsLoadingSummary;

  /// No description provided for @matchStatsSectionField.
  ///
  /// In es, this message translates to:
  /// **'Campo final'**
  String get matchStatsSectionField;

  /// No description provided for @matchStatsFormationChip.
  ///
  /// In es, this message translates to:
  /// **'Formación: {formation}'**
  String matchStatsFormationChip(String formation);

  /// No description provided for @matchStatsFieldDispositionHint.
  ///
  /// In es, this message translates to:
  /// **'Disposición según las posiciones guardadas al terminar el partido.'**
  String get matchStatsFieldDispositionHint;

  /// No description provided for @matchStatsSectionTimeline.
  ///
  /// In es, this message translates to:
  /// **'Cronología'**
  String get matchStatsSectionTimeline;

  /// No description provided for @matchStatsTimelineEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay eventos registrados'**
  String get matchStatsTimelineEmpty;

  /// No description provided for @matchStatsTimelineEmptyHint.
  ///
  /// In es, this message translates to:
  /// **'Los goles, cambios y tarjetas aparecerán aquí cuando se registren en el partido.'**
  String get matchStatsTimelineEmptyHint;

  /// No description provided for @matchStatsMinutesPlayed.
  ///
  /// In es, this message translates to:
  /// **'Minutos jugados'**
  String get matchStatsMinutesPlayed;

  /// No description provided for @matchStatsStatGoals.
  ///
  /// In es, this message translates to:
  /// **'Goles'**
  String get matchStatsStatGoals;

  /// No description provided for @matchStatsStatAssists.
  ///
  /// In es, this message translates to:
  /// **'Asistencias'**
  String get matchStatsStatAssists;

  /// No description provided for @matchStatsStatGoodPasses.
  ///
  /// In es, this message translates to:
  /// **'Pases buenos'**
  String get matchStatsStatGoodPasses;

  /// No description provided for @matchStatsStatBadPasses.
  ///
  /// In es, this message translates to:
  /// **'Pases malos'**
  String get matchStatsStatBadPasses;

  /// No description provided for @matchStatsStatGoodPlays.
  ///
  /// In es, this message translates to:
  /// **'Buenas jugadas'**
  String get matchStatsStatGoodPlays;

  /// No description provided for @matchStatsStatBadPlays.
  ///
  /// In es, this message translates to:
  /// **'Malas jugadas'**
  String get matchStatsStatBadPlays;

  /// No description provided for @matchStatsOurGoalChip.
  ///
  /// In es, this message translates to:
  /// **'Gol a favor'**
  String get matchStatsOurGoalChip;

  /// No description provided for @matchStatsOwnGoalChip.
  ///
  /// In es, this message translates to:
  /// **'Autogol'**
  String get matchStatsOwnGoalChip;

  /// No description provided for @matchListLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando partidos…'**
  String get matchListLoading;

  /// No description provided for @matchListEmptyStateTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin partidos todavía'**
  String get matchListEmptyStateTitle;

  /// No description provided for @matchListEmptyStateBody.
  ///
  /// In es, this message translates to:
  /// **'Los partidos que crees desde la convocatoria aparecerán aquí. Desliza hacia abajo para actualizar.'**
  String get matchListEmptyStateBody;

  /// No description provided for @matchListCalendarTitle.
  ///
  /// In es, this message translates to:
  /// **'Calendario'**
  String get matchListCalendarTitle;

  /// No description provided for @matchListElapsedTime.
  ///
  /// In es, this message translates to:
  /// **'Tiempo: {time}'**
  String matchListElapsedTime(String time);

  /// No description provided for @matchListHintLineupStart.
  ///
  /// In es, this message translates to:
  /// **'Pulsa para alinear y empezar'**
  String get matchListHintLineupStart;

  /// No description provided for @matchListHintManageResume.
  ///
  /// In es, this message translates to:
  /// **'Pulsa para gestionar o reanudar'**
  String get matchListHintManageResume;

  /// No description provided for @matchListHintViewStats.
  ///
  /// In es, this message translates to:
  /// **'Pulsa para ver estadísticas'**
  String get matchListHintViewStats;

  /// No description provided for @matchLineupSquadTitle.
  ///
  /// In es, this message translates to:
  /// **'Plantilla del partido'**
  String get matchLineupSquadTitle;

  /// No description provided for @matchLineupStarters.
  ///
  /// In es, this message translates to:
  /// **'Titulares'**
  String get matchLineupStarters;

  /// No description provided for @matchLineupSubstitutes.
  ///
  /// In es, this message translates to:
  /// **'Suplentes'**
  String get matchLineupSubstitutes;

  /// No description provided for @matchLineupStarterTag.
  ///
  /// In es, this message translates to:
  /// **'Titular'**
  String get matchLineupStarterTag;

  /// No description provided for @matchLineupSubstituteTag.
  ///
  /// In es, this message translates to:
  /// **'Suplente'**
  String get matchLineupSubstituteTag;

  /// No description provided for @matchFieldSelectPlayerFirst.
  ///
  /// In es, this message translates to:
  /// **'Selecciona primero un jugador en la lista'**
  String get matchFieldSelectPlayerFirst;

  /// No description provided for @matchFieldMaxPlayersExpulsionRule.
  ///
  /// In es, this message translates to:
  /// **'No puedes tener más jugadores en el campo. Por cada expulsado debe quedar un hueco libre.'**
  String get matchFieldMaxPlayersExpulsionRule;

  /// No description provided for @matchConvocationTableEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay jugadores convocados para este partido'**
  String get matchConvocationTableEmpty;

  /// No description provided for @matchDeletedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Partido eliminado correctamente'**
  String get matchDeletedSuccess;

  /// No description provided for @matchEventLegacyActionRegistered.
  ///
  /// In es, this message translates to:
  /// **'Acción registrada'**
  String get matchEventLegacyActionRegistered;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
