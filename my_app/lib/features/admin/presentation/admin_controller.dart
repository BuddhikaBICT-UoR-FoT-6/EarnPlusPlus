import 'package:flutter/foundation.dart'; // for ChangeNotifier, which allows the
// AdminController to notify listeners when its state changes, enabling reactive
// UI updates

import '../data/admin_repository.dart';
import '../domain/admin_models.dart';

// AdminLoadState is an enum that defines the various states of loading data for
// the admin dashboard. It includes states such as idle, loading, success, forbidden,
// unauthorized, and error. This enum is used to manage the UI state based on the
// current status of data fetching and processing, allowing the UI to display
// appropriate feedback to the user, such as loading indicators, error messages, or
// the admin dashboard content based on the current load state.
enum AdminLoadState { idle, loading, success, forbidden, unauthorized, error }

// AdminController is a ChangeNotifier that manages the state and data for the admin
// dashboard. It interacts with the AdminRepository to fetch data such as the current
// user's account information, admin summary, super admin summary, and the list of users.
// It also provides a method to change user roles. The controller maintains the
//current load state, any error messages, and the data needed for the admin dashboard.
// It notifies listeners whenever there are changes to the state or data, allowing
// the UI to react and update accordingly based on the current state of the admin dashboard.
class AdminController extends ChangeNotifier {
  final AdminRepository _repository; // the AdminRepository is injected into the
  // controller, allowing for separation of concerns and easier testing by providing
  // a way to mock the repository during tests to simulate different scenarios and
  // responses from the backend API without relying on the actual implementation
  // of the repository or making real network requests during testing and development

  AdminController({AdminRepository? repository})
    : _repository =
          repository ?? AdminRepository(); // if no repository is provided,
  // it creates a default instance of AdminRepository using the default constructor,
  // allowing for flexibility in how the controller is instantiated and making it

  AdminLoadState state =
      AdminLoadState.idle; // initial state is idle, indicating
  // that no data fetching has started yet
  String? error; // a nullable string to hold any error messages that may occur
  // during data fetching
  UserAccount? me; // a nullable UserAccount to hold the current user's account
  // information, which can be used by the UI to display user details or manage
  // user-specific admin functionalities
  AdminSummary?
  adminSummary; // a nullable AdminSummary to hold the summary data
  // for the admin dashboard, which can be used by the UI to display key metrics
  // and information relevant
  SuperAdminSummary? superAdminSummary; // a nullable SuperAdminSummary to hold
  //the summary data for the super admin
  List<UserAccount> users = const []; // a list of UserAccount objects to hold
  //the list of user accounts
  bool roleUpdateInProgress =
      false; // a boolean flag to indicate whether a role
  // update operation is in progress,

  // the loadAdminDashboard method is responsible for fetching the necessary data
  // for the admin dashboard. It updates the state to loading, clears any previous
  // errors, fetches the current user's account information, admin summary, and
  // the list of users, and then updates the state to success or error based on
  // the outcome of the data fetching operations. It also handles specific
  // exceptions such as AdminUnauthorizedException and AdminForbiddenException
  // to set the appropriate state and error messages. The method uses notifyListeners()
  // to inform the UI that the state has changed, ensuring that the UI updates
  // to reflect the current state of the admin dashboard, including loading
  // indicators, error messages, or the fetched data.
  Future<void> loadAdminDashboard() async {
    state = AdminLoadState.loading;
    error = null;
    notifyListeners();

    try {
      me = await _repository
          .fetchMe(); // fetches the current user's account information
      // from the repository, which can be used to display user details or manage
      // user-specific admin functionalities
      adminSummary = await _repository.fetchAdminSummary(); // fetches the admin
      // dashboard summary data from the repository, which can be used to display
      // key metrics and information relevant to the admin dashboard
      users = await _repository
          .fetchUsers(); // fetches the list of user accounts
      // from the repository, which can be used to display user details or manage
      // user-specific admin functionalities
      state =
          AdminLoadState.success; // updates the state to success if all data
      // fetching operations are successful
    } on AdminUnauthorizedException {
      state = AdminLoadState.unauthorized;
    } on AdminForbiddenException {
      state = AdminLoadState.forbidden;
    } catch (e) {
      state = AdminLoadState.error;
      error = 'Failed to load admin dashboard: $e';
    }

    notifyListeners();
  }

  // the loadSuperAdminDashboard method is responsible for fetching the necessary data
  // for the super admin dashboard. It updates the state to loading, clearing any previous
  // errors, fetching the current user's account information, super admin summary,
  // and the list of users, and then updating the state to success or error based
  // on the outcome of the data fetching operations. It also handles specific
  // exceptions such as AdminUnauthorizedException and AdminForbiddenException
  // to set the appropriate state and error messages. The method uses notifyListeners()
  // to inform the UI that the state has changed, ensuring that the UI updates
  // to reflect the current state of the super admin dashboard.
  Future<void> loadSuperAdminDashboard() async {
    state =
        AdminLoadState.loading; // also sets the state to loading to indicate
    // that data fetching is in progress
    error = null;
    notifyListeners();

    try {
      me = await _repository.fetchMe(); // fetches the current user's account
      // information from the repository
      superAdminSummary = await _repository.fetchSuperAdminSummary(); // fetches
      // the super admin dashboard summary data from the repository
      users = await _repository
          .fetchUsers(); // fetches the list of user accounts
      // from the repository and updates the users list in the controller state
      state = AdminLoadState
          .success; // updates the state to success if all data fetching
    } on AdminUnauthorizedException {
      state = AdminLoadState.unauthorized;
    } on AdminForbiddenException {
      state = AdminLoadState.forbidden;
    } catch (e) {
      state = AdminLoadState.error;
      error = 'Failed to load superadmin dashboard: $e';
    }

    notifyListeners();
  }

  // the changeRole method is responsible for updating the role of a user. It updates
  // the state to indicate that the role update is in progress, clears any previous
  // errors, and then attempts to update the user's role in the repository. If
  // the update is successful, it updates the users list in the controller state.
  // If an error occurs, it sets the appropriate error message. Finally, it updates
  // the state to indicate that the role update is complete.
  Future<void> changeRole({required int userId, required String role}) async {
    roleUpdateInProgress =
        true; // indicates that the role update is in progress
    // to manage UI state, such as showing a loading indicator or disabling role change buttons
    error = null;
    notifyListeners();

    try {
      await _repository.updateUserRole(userId: userId, role: role); // attempts
      // to update the user's role in the repository and waits for the operation
      // to complete before proceeding to update the local state
      users = users
          // if the role update is successful, it updates the users list in the
          // controller state by mapping through the existing users and updating the
          // role of the user with the matching userId, while keeping the other user
          // details unchanged and then converting the result back to a list to update
          // the users state with the updated role information for the specified user
          .map(
            (u) => u.id == userId
                ? UserAccount(
                    id: u.id,
                    email: u.email,
                    role: role,
                    createdAt: u.createdAt,
                  )
                : u,
          )
          .toList();
    } catch (e) {
      // keeps the last mutation failure available to the UI so the dashboard can
      // provide immediate feedback when role updates fail.
      error = 'Failed to update role: $e';
    } finally {
      // always clear the mutation flag to re-enable role controls even if the
      // network request throws, then notify listeners to refresh button states.
      roleUpdateInProgress = false;
      notifyListeners();
    }
  }
}
