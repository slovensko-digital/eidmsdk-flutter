package sk.freevision.eidmsdk

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.test.Test
import org.mockito.ArgumentMatchers.anyString
import org.mockito.Mockito

/**
 * Unit tests for the argument handling in [EidmsdkPlugin.onMethodCall].
 *
 * Only the paths that touch no Android framework class and need no Activity are
 * covered here — a plain JVM unit test has stub `android.os.Build` values and no
 * `ComponentActivity`, so the SDK-invoking branches cannot run. Those are
 * exercised by the example app's integration tests instead.
 *
 * Run with `./gradlew :eidmsdk:testDebugUnitTest` from `example/android/`.
 */
internal class EidmsdkPluginTest {
    private val plugin = EidmsdkPlugin()

    private fun call(method: String, arguments: Any?): MethodChannel.Result {
        val result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(MethodCall(method, arguments), result)

        return result
    }

    @Test
    fun `unknown method is reported as not implemented`() {
        val result = call("noSuchMethod", emptyMap<String, Any?>())

        Mockito.verify(result).notImplemented()
    }

    @Test
    fun `non-map arguments are rejected`() {
        val result = call("setLogLevel", "not a map")

        Mockito.verify(result).error(
            Mockito.eq("ERROR_PARSE_ARGUMENTS"),
            anyString(),
            Mockito.any(),
        )
    }

    @Test
    fun `a missing required argument reports which one, naming it in details`() {
        // Previously these were read with !!, so a missing argument threw out of
        // onMethodCall and the awaiting Dart Future never completed.
        val cases = mapOf(
            "setLogLevel" to "logLevel",
            "getCertificates" to "type",
            "signData" to "certIndex",
        )

        for ((method, argument) in cases) {
            val result = call(method, emptyMap<String, Any?>())

            Mockito.verify(result).error(
                Mockito.eq("ERROR_PARSE_ARGUMENTS"),
                anyString(),
                Mockito.eq(argument),
            )
        }
    }

    @Test
    fun `a wrongly typed required argument is rejected rather than crashing`() {
        val result = call("getCertificates", mapOf("type" to "not an int"))

        Mockito.verify(result).error(
            Mockito.eq("ERROR_PARSE_ARGUMENTS"),
            anyString(),
            Mockito.eq("type"),
        )
    }
}
