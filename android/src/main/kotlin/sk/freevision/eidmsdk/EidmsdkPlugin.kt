package sk.freevision.eidmsdk

import android.content.Intent
import android.util.Base64
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts.StartActivityForResult
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import sk.eid.eidhandlerpublic.EIDCertificateType
import sk.eid.eidhandlerpublic.EIDContracts
import sk.eid.eidhandlerpublic.EIDEnvironment
import sk.eid.eidhandlerpublic.EIDHandler
import java.security.MessageDigest

/**
 * `EidmsdkPlugin` Android implementation.
 *
 * Note [startTutorialActivityLauncher], [getCertificatesActivityLauncher] and
 * [signDataActivityLauncher] - registering it in handler method would result into error:
 * java.lang.IllegalStateException: LifecycleOwner sk.freevision.eidmsdk_example.MainActivity@837366e is attempting to register while current state is RESUMED. LifecycleOwners must call register before they are STARTED.
 *
 */
class EidmsdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    /** MethodChannel for communication between Flutter and native Android. */
    private lateinit var channel: MethodChannel

    /** Activity needed for mSDK. */
    private lateinit var activity: ComponentActivity

    /** [ActivityResultLauncher] for [EIDHandler.startTutorial]. */
    private lateinit var startTutorialActivityLauncher: ActivityResultLauncher<Intent>

    /** [ActivityResultLauncher] for [EIDHandler.getCertificates]. */
    private lateinit var getCertificatesActivityLauncher: ActivityResultLauncher<Intent>

    /** [ActivityResultLauncher] for [EIDHandler.startSign]. */
    private lateinit var signDataActivityLauncher: ActivityResultLauncher<Intent>

    /** Latest Flutter [Result] to be used to return result from [EIDHandler.getCertificates]. */
    private var getCertificatesResult: Result? = null

    /** Latest Flutter [Result] to be used to return result from [EIDHandler.startSign]. */
    private var signDataResult: Result? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "eidmsdk")
        channel.setMethodCallHandler(this)

        // EID SDK initialization
        EIDHandler.initialize(flutterPluginBinding.applicationContext, EIDEnvironment.MINV_PROD)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.d(TAG, "onAttachedToActivity")

        val componentActivity = binding.activity as? ComponentActivity

        requireNotNull(componentActivity) {
            "Activity has to be androidx.activity.ComponentActivity."
        }

        activity = componentActivity

        startTutorialActivityLauncher = activity.registerForActivityResult(
            StartActivityForResult()
        ) { }
        getCertificatesActivityLauncher = activity.registerForActivityResult(
            EIDContracts.GetCertificates(), ::onGetCertificatesResult,
        )
        signDataActivityLauncher = activity.registerForActivityResult(
            EIDContracts.StartSign(), ::onSignDataResult,
        )
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Log.d(TAG, "onDetachedFromActivityForConfigChanges")
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        Log.d(TAG, "onReattachedToActivityForConfigChanges: activity=${binding.activity}")
    }

    override fun onDetachedFromActivity() {
        Log.d(TAG, "onDetachedFromActivity")
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        Log.d(TAG, "onMethodCall: call=(method=${call.method}, arguments=${call.arguments})")

        // Every method call arguments expected it to be Map<String, Any?>
        if (call.arguments !is Map<*, *>) {
            result.error(
                /* errorCode = */ "ERROR_PARSE_ARGUMENTS",
                /* errorMessage = */ "Error parsing arguments",
                /* errorDetails = */ call.arguments.toString(),
            )
            return
        }

        when (call.method) {
            "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")

            "setLogLevel" -> result.setLogLevel(
                logLevel = call.argument("logLevel")!!,
            )

            "showTutorial" -> result.showTutorial(
                language = call.argument("language"),
            )

            "getCertificates" -> result.getCertificates(
                types = call.argument("types")!!,
                language = call.argument("language"),
            )

            "signData" -> result.signData(
                certIndex = call.argument("certIndex")!!,
                signatureScheme = call.argument("signatureScheme")!!,
                dataToSign = call.argument("dataToSign")!!,
                isBase64Encoded = call.argument("isBase64Encoded")!!,
                language = call.argument("language"),
            )

            else -> result.notImplemented()
        }
    }

    private fun Result.setLogLevel(@Suppress("UNUSED_PARAMETER") logLevel: Int) {
        Log.w(TAG, "Not supported in Android.")

        success(false)
    }

    private fun Result.showTutorial(language: String?) {
        EIDHandler.startTutorial(
            activity = activity,
            activityLauncher = startTutorialActivityLauncher,
            language = language,
        )

        success(false)
    }

    private fun Result.getCertificates(types: Collection<Int>, language: String?) {
        val type = types.singleOrNull()

        requireNotNull(type) { "types has to contain exactly single int value." }

        val certificateType = EIDCertificateType.values()[type]

        getCertificatesResult = this

        EIDHandler.getCertificates(
            certificateType = certificateType,
            activity = activity,
            activityLauncher = getCertificatesActivityLauncher,
            language = language,
        )
    }

    private fun Result.signData(
        certIndex: Int,
        signatureScheme: String,
        dataToSign: String,
        isBase64Encoded: Boolean = false,
        language: String?
    ) {
        signDataResult = this

        // Need to generate hash 1st
        val digest: MessageDigest = MessageDigest.getInstance("SHA-256")
        var finalByteArrayToSign: ByteArray = dataToSign.toByteArray()
        if (isBase64Encoded) {
            finalByteArrayToSign = Base64.decode(dataToSign, Base64.DEFAULT)
        }
        val generatedHash: ByteArray = digest.digest(finalByteArrayToSign)
        val dataToSignB64 = Base64.encodeToString(generatedHash, Base64.NO_WRAP)

        EIDHandler.startSign(
            certIndex = certIndex,
            signatureScheme = signatureScheme,
            dataToSign = dataToSignB64,
            activity = activity,
            activityLauncher = signDataActivityLauncher,
            language = language,
        )
    }

    private fun onGetCertificatesResult(result: kotlin.Result<String?>) {
        var channelResult by ::getCertificatesResult

        result.fold(
            onSuccess = {
                channelResult?.success(it)
            } ,
            onFailure = {
                channelResult?.error(
                    "ERROR_READ_CERTIFICATE",
                    "Chyba pri načítaní podpisového certifikátu.",
                    it.message,
                )
            }
        )

        channelResult = null
    }

    private fun onSignDataResult(result: kotlin.Result<String>) {
        var channelResult by ::signDataResult

        result.onSuccess {
            channelResult?.success(it)
        }.onFailure {
            channelResult?.error(
                "ERROR_SIGNING",
                "Chyba pri podpisovaní.",
                it.message,
            )
        }

        channelResult = null
    }

    companion object {
        private const val TAG: String = "EidmsdkPlugin"
    }
}
