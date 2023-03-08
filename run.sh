# check JDK
java -version 2>&1 | grep -iE openjdk.+32-Bit.+build.19 ||
    exit -1

# get Jar
[ -f javassist.jar ] ||
    wget https://github.com/jboss-javassist/javassist/releases/download/rel_3_29_2_ga/javassist.jar
    
# build agent
cat << EOI > Agent.java
import java.lang.instrument.*;
import javassist.*;
import java.security.*;

public class Agent {
    public static void premain(String agentArgs, Instrumentation instrumentation) {
        instrumentation.addTransformer(new TracingClassfileTransformer(agentArgs));
    }
}

class TracingClassfileTransformer implements ClassFileTransformer {
    public TracingClassfileTransformer(String agentArgs) {
    }

    @Override public byte[] transform(ClassLoader loader,
                                      String className,
                                      Class<?> classBeingRedefined,
                                      ProtectionDomain protectionDomain,
                                      byte[] classfileBuffer) {
        byte[] byteCode = classfileBuffer;
        if(className != null)
            try {
                ClassPool classPool = ClassPool.getDefault();
                CtClass ctClass = classPool.get(className.replace('/', '.'));
                for(CtMethod method: ctClass.getDeclaredMethods()) {
                    boolean instrumentMethod = !method.isEmpty()
                        && !Modifier.isNative(method.getModifiers());
                    if(instrumentMethod) {
                        method.insertBefore(String.format("System.out.println(\"=> %s.%s\");",
                                                          className,
                                                          method.getName()));
                        method.insertAfter(String.format("System.out.println(\"<= %s.%s\");",
                                                         className,
                                                         method.getName()));
                    }
                }
                byteCode = ctClass.toBytecode();
                ctClass.detach();
            }

            catch(Exception exception) {
                exception.printStackTrace();
            }
        return byteCode;
    }
}

class Hello {
    public static void main(String... args) {
        System.out.println("Hello");
    }
}
EOI
javac -cp javassist.jar Agent.java
echo "Premain-Class: Agent" > MANIFEST.MF
jar cvfm agent.jar MANIFEST.MF TracingClassfileTransformer.class Agent.class

# succeeds
java -javaagent:agent.jar Hello

# fails
java --enable-preview -javaagent:agent.jar Hello
