class Profile {
    id: string;
    user_id: string;
    name: string;
    profile_type: string | null;
    avatar_id: string;
    created_at: string;
    updated_at: string;
    preferences: any[];
  
    constructor(data: Profile) {
      this.id = data.id;
      this.user_id = data.user_id;
      this.name = data.name;
      this.profile_type = data.profile_type;
      this.avatar_id = data.avatar_id;
      this.created_at = data.created_at;
      this.updated_at = data.updated_at;
      this.preferences = data.preferences || [];
    }
  
    // Puedes agregar métodos adicionales según tus necesidades
  }
  
  export default Profile;
  