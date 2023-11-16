// user.ts

import Profile from './Profile';

class User {
    private static currentUser: User | null = null;
    id: string;
    email: string;
    created_at: string;
    updated_at: string;
    username: string;
    customer_id: string | null;
    profiles: Profile[];
    admin: boolean;
    current_profile: Profile | null;

    constructor(data: User) {
        this.id = data.id;
        this.email = data.email;
        this.created_at = data.created_at;
        this.updated_at = data.updated_at;
        this.username = data.username;
        this.customer_id = data.customer_id;
        this.profiles = (data.profiles || []).map((profileData: any) => new Profile(profileData));
        this.admin = data.admin;
        this.current_profile = data.current_profile ? new Profile(data.current_profile) : null;
    }

    getPreferences() {
        return this.current_profile ? this.current_profile.preferences : [];
    }

}

export default User;
