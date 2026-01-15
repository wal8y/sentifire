package com.example.sentifire

import org.json.JSONArray
import org.json.JSONObject

data class NetworkInfo(
    val ssid: String,
    val ownIp: String,
    val gatewayIp: String,
    val subnetMask: String,
    val dnsServers: List<String>,
    val connectionType: String,
    val isConnected: Boolean
) {
    fun toJson(): JSONObject {
        val json = JSONObject()
        json.put("ssid", ssid)
        json.put("ownIp", ownIp)
        json.put("gatewayIp", gatewayIp)
        json.put("subnetMask", subnetMask)
        json.put("dnsServers", JSONArray(dnsServers))
        json.put("connectionType", connectionType)
        json.put("isConnected", isConnected)
        return json
    }
}
