import { defineStore } from 'pinia';
import User from '../models/User';

interface CurrentUserState {
  currentUser: User | null;
}

export const useCurrentUser = defineStore('current-user', {
  state: (): CurrentUserState => ({
    currentUser: null,
  }),
  actions: {
    setUser(newUser: User): void {
      this.currentUser = newUser;
    },
    clearUser(): void {
      this.currentUser = null;
    },
  },
  getters: {
    isLoggedIn(): boolean {
      return this.currentUser !== null;
    },
    isMainProfile(): boolean {
        return this.currentUser ? this.currentUser.current_profile ? this.currentUser.current_profile.id === this.currentUser.profiles[0].id : false : false;
    }
  },
});
