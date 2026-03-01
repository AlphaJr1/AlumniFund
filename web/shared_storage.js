// Shared storage helper untuk cross-profile testing
// Menggunakan localStorage dengan key global

const SHARED_USERS_KEY = 'brand_identity_shared_users';

// Get all users from shared storage
function getSharedUsers() {
  try {
    const data = localStorage.getItem(SHARED_USERS_KEY);
    return data ? JSON.parse(data) : [];
  } catch (e) {
    console.error('Error reading shared users:', e);
    return [];
  }
}

// Save users to shared storage
function saveSharedUsers(users) {
  try {
    localStorage.setItem(SHARED_USERS_KEY, JSON.stringify(users));
  } catch (e) {
    console.error('Error saving shared users:', e);
  }
}

// Find user by name
function findUserByName(displayName) {
  const users = getSharedUsers();
  return users.find(u => u.displayName.toLowerCase() === displayName.toLowerCase());
}

// Find user by fingerprint
function findUserByFingerprint(fingerprint) {
  const users = getSharedUsers();
  return users.find(u => u.fingerprints && u.fingerprints.includes(fingerprint));
}

// Save or update user
function saveSharedUser(userData) {
  const users = getSharedUsers();
  const index = users.findIndex(u => u.userId === userData.userId);

  if (index >= 0) {
    users[index] = userData;
  } else {
    users.push(userData);
  }

  saveSharedUsers(users);
}

// Clear all shared users
function clearSharedUsers() {
  localStorage.removeItem(SHARED_USERS_KEY);
}

// Expose to window for Dart interop
window.sharedStorage = {
  getUsers: getSharedUsers,
  saveUsers: saveSharedUsers,
  findUserByName: findUserByName,
  findUserByFingerprint: findUserByFingerprint,
  saveUser: saveSharedUser,
  clearUsers: clearSharedUsers
};