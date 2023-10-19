//
//  Throwable.swift
//  SwiftJava
//
//  Created by John Holdsworth on 17/07/2016.
//  Copyright (c) 2016 John Holdsworth. All rights reserved.
//
//  Conversion to/from Java primitives/objects from basic Swift types.
//

open class Throwable {

    private let javaObject: jobject

    public required init(javaObject: jobject) {
        self.javaObject = javaObject
    }

    private static var getMessage_MethodID_10: jmethodID?
    private static var getStackTrace_MethodID_11: jmethodID?
    private static var toString_MethodID_9: jmethodID?
    private static var printStackTrace_MethodID_15: jmethodID?
    private static var classGetNameMethod: jmethodID?

    open func getMessage() -> String! {
        var __locals = [jobject]()
        var __args = [jvalue]( repeating: jvalue(), count: 1 )
        let __return = JNIMethod.CallObjectMethod( object: javaObject, methodName: "getMessage", methodSig: "()Ljava/lang/String;", methodCache: &Throwable.getMessage_MethodID_10, args: &__args, locals: &__locals )
        defer { JNI.DeleteLocalRef( __return ) }
        return __return != nil ? String( javaObject: __return ) : nil
    }

    open func getStackTrace() -> [String] {
        var __locals = [jobject]()
        var __args = [jvalue]( repeating: jvalue(), count: 1 )
        guard let stackTraces = JNIMethod.CallObjectMethod( object: javaObject, methodName: "getStackTrace", methodSig: "()[Ljava/lang/StackTraceElement;", methodCache: &Throwable.getStackTrace_MethodID_11, args: &__args, locals: &__locals ) else {
            return []
        }
        defer { JNI.DeleteLocalRef(stackTraces) }
        let length: jsize = JNI.api.GetArrayLength(JNI.env, stackTraces)
        var result = [String]()
        for index in 0 ..< length {
            let stackTrace = JNI.api.GetObjectArrayElement(JNI.env, stackTraces, index)
            guard let jstring = JNIMethod.CallObjectMethod(object: stackTrace, methodName: "toString", methodSig: "()Ljava/lang/String;", methodCache: &Throwable.toString_MethodID_9, args: &__args, locals: &__locals) else {
                continue
            }
            defer { JNI.DeleteLocalRef(jstring) }
            result.append(String(javaObject: jstring))
        }
        return result
    }

    open func printStackTrace() {
        var __locals = [jobject]()
        var __args = [jvalue]( repeating: jvalue(), count: 1 )
        JNIMethod.CallVoidMethod( object: javaObject, methodName: "printStackTrace", methodSig: "()V", methodCache: &Throwable.printStackTrace_MethodID_15, args: &__args, locals: &__locals )
    }

    public func className() -> String {
        let cls = JNI.api.GetObjectClass(JNI.env, javaObject)
        var __locals = [jobject]()
        var __args = [jvalue]( repeating: jvalue(), count: 1 )
        __args[0] = jvalue(l: cls)
        let javaClassName = JNIMethod.CallObjectMethod(object: cls, methodName: "getName", methodSig: "()Ljava/lang/String;", methodCache: &Throwable.classGetNameMethod, args: &__args, locals: &__locals)
        let className = String(javaObject: javaClassName)
        JNI.DeleteLocalRef(cls)
        JNI.DeleteLocalRef(javaClassName)
        return className
    }

    public func stackTraceString() -> String {
        var stackTrace = ""
        let stackTraces = getStackTrace() 
        for trace in stackTraces {
            stackTrace += "\n\(trace)"
        }
        stackTrace += "\n"
        return stackTrace
    }

    public func lastStackTraceString() -> String? {
        return nil
    }

}