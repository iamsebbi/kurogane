package com.kurogane.mobile

import androidx.credentials.CredentialManager
import androidx.credentials.GetCredentialRequest
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialException
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.kurogane.mobile/google_identity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "signInWithGoogle") {
                val serverClientId = call.argument<String>("serverClientId")
                if (serverClientId.isNullOrBlank()) {
                    result.error("INVALID_ARGS", "Server client ID is required", null)
                    return@setMethodCallHandler
                }
                val filterByAuthorizedAccounts = call.argument<Boolean>("filterByAuthorizedAccounts") ?: false

                val credentialManager = CredentialManager.create(this)
                val googleIdOption = GetGoogleIdOption.Builder()
                    .setFilterByAuthorizedAccounts(filterByAuthorizedAccounts)
                    .setServerClientId(serverClientId)
                    .setAutoSelectEnabled(false)
                    .build()

                val signInWithGoogleOption = GetSignInWithGoogleOption.Builder(serverClientId)
                    .build()

                val request = GetCredentialRequest.Builder()
                    .addCredentialOption(googleIdOption)
                    .addCredentialOption(signInWithGoogleOption)
                    .build()

                CoroutineScope(Dispatchers.Main).launch {
                    try {
                        val credentialResponse = credentialManager.getCredential(this@MainActivity, request)
                        val credential = credentialResponse.credential
                        val googleIdTokenCredential = GoogleIdTokenCredential.createFrom(credential.data)

                        val dataMap = mapOf(
                            "idToken" to googleIdTokenCredential.idToken,
                            "id" to googleIdTokenCredential.id,
                            "displayName" to (googleIdTokenCredential.displayName ?: ""),
                            "profilePictureUri" to (googleIdTokenCredential.profilePictureUri?.toString() ?: "")
                        )
                        result.success(dataMap)
                    } catch (e: GetCredentialCancellationException) {
                        result.error("CANCELED", "User canceled sign in", null)
                    } catch (e: GetCredentialException) {
                        // Fallback retry cu GetSignInWithGoogleOption explicit
                        try {
                            val explicitRequest = GetCredentialRequest.Builder()
                                .addCredentialOption(GetSignInWithGoogleOption.Builder(serverClientId).build())
                                .build()
                            val credentialResponse = credentialManager.getCredential(this@MainActivity, explicitRequest)
                            val credential = credentialResponse.credential
                            val googleIdTokenCredential = GoogleIdTokenCredential.createFrom(credential.data)

                            val dataMap = mapOf(
                                "idToken" to googleIdTokenCredential.idToken,
                                "id" to googleIdTokenCredential.id,
                                "displayName" to (googleIdTokenCredential.displayName ?: ""),
                                "profilePictureUri" to (googleIdTokenCredential.profilePictureUri?.toString() ?: "")
                            )
                            result.success(dataMap)
                        } catch (e2: GetCredentialCancellationException) {
                            result.error("CANCELED", "User canceled sign in", null)
                        } catch (e2: Exception) {
                            result.error("CREDENTIAL_ERROR", e2.message ?: e.message, null)
                        }
                    } catch (e: Exception) {
                        result.error("UNKNOWN_ERROR", e.message, null)
                    }
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
