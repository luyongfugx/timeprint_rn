package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models

import com.google.gson.annotations.SerializedName
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.GenerateNoArg
@GenerateNoArg
data class TeamMember(
    @SerializedName("id")
    val id: String,
    
    @SerializedName("name")
    val name: String,
    
    @SerializedName("avatar")
    val avatar: String,
    
    @SerializedName("position")
    val position: String,
    
    @SerializedName("department")
    val department: String,
    
    @SerializedName("phone")
    val phone: String,
    
    @SerializedName("email")
    val email: String,
    
    @SerializedName("lastCheckinTime")
    val lastCheckinTime: String,
    
    @SerializedName("lastLocation")
    val lastLocation: String,
    
    @SerializedName("status")
    val status: String, // "online" | "offline" | "away"
    
    @SerializedName("team_id")
    val teamId: String? = null,
    
    @SerializedName("role")
    val role: String? = null
)
@GenerateNoArg
data class TeamMembership(
    @SerializedName("team_id")
    val teamId: String,
    
    @SerializedName("role")
    val role: String,
    
    @SerializedName("teams")
    val teams: TeamInfo
)
@GenerateNoArg
data class TeamInfo(
    @SerializedName("id")
    val id: String,
    
    @SerializedName("name")
    val name: String,
    
    @SerializedName("avatar")
    val avatar: String? = null,
    
    @SerializedName("description")
    val description: String? = null,
    
    @SerializedName("member_count")
    val memberCount: Int? = null,
    
    @SerializedName("created_at")
    val createdAt: String? = null,
    
    @SerializedName("updated_at")
    val updatedAt: String? = null
)
