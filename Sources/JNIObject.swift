//
//  JNIObject.swift
//  SwiftJava
//
//  Created by John Holdsworth on 14/07/2016.
//  Copyright (c) 2016 John Holdsworth. All rights reserved.
//
//  Core protocols and implementation of JNIObject which represents
//  a Java oject by class or by interface inside a Swift program.
//  Basic conversion to/from these object types and containers.
//

import Foundation

public protocol JNIObjectProtocol {

    func localJavaObject( _ locals: UnsafeMutablePointer<[jobject]> ) -> jobject?

}

public protocol JNIObjectInit {

    init( javaObject: jobject? )

}

extension JNIObjectProtocol {

    public func withJavaObject<Result>( _ body: @escaping (jobject?) throws -> Result ) rethrows -> Result {
        var locals = [jobject]()
        let javaObject: jobject? = localJavaObject( &locals )
        defer {
            for local in locals {
                JNI.DeleteLocalRef( local )
            }
        }
        return try body( javaObject )
    }
}

public protocol JavaProtocol: JNIObjectProtocol {
}

open class JNIObject: JNIObjectProtocol, JNIObjectInit {

    private var _javaObject: jobject?

    open var javaObject: jobject? {
        get {
            return _javaObject
        }
        set(newValue) {
            if newValue != _javaObject {
                let oldValue: jobject? = _javaObject
                if newValue != nil {
                    _javaObject = JNI.api.NewGlobalRef( JNI.env, newValue )
                }
                else {
                    _javaObject = nil
                }
                if oldValue != nil {
                    JNI.api.DeleteGlobalRef( JNI.env, oldValue )
                }
            }
        }
    }

    public required init( javaObject: jobject? ) {
        self.javaObject = javaObject
    }

    public convenience init() {
        self.init( javaObject: nil )
    }

    open var isNull: Bool {
        return _javaObject == nil || JNI.api.IsSameObject( JNI.env, _javaObject, nil ) == jboolean(JNI_TRUE)
    }

    open func localJavaObject( _ locals: UnsafeMutablePointer<[jobject]> ) -> jobject? {
        if let local: jobject = _javaObject != nil ? JNI.api.NewLocalRef( JNI.env, _javaObject ) : nil {
            locals.pointee.append( local )
            return local
        }
        return nil
    }

    open func clearLocal() {
    }

    deinit {
        javaObject = nil
    }
}

open class JNIObjectForward: JNIObject {
}

extension String: JNIObjectProtocol {

    public func localJavaObject( _ locals: UnsafeMutablePointer<[jobject]> ) -> jobject? {
        if let javaObject: jstring =  self.withCString( { ptr in
            JNI.env?.pointee?.pointee.NewStringUTF( JNI.env, ptr )
        } ) {
            locals.pointee.append( javaObject )
            return javaObject
        }
        return nil
    }
}

extension String: JNIObjectInit {

    public init( javaObject: jobject? ) {
        var isCopy: jboolean = 0
        if let javaObject: jobject = javaObject, let value: UnsafePointer<jchar> = JNI.api.GetStringChars( JNI.env, javaObject, &isCopy ) {
            self.init( utf16CodeUnits: value, count: Int(JNI.api.GetStringLength( JNI.env, javaObject )) )
            if isCopy != 0 || true {
                JNI.api.ReleaseStringChars( JNI.env, javaObject, value ) ////
            }
        }
        else {
            self.init()
        }
    }
}

extension jobject {

    public func arrayMap<T>( block: ( _ javaObject: jobject? ) -> T ) -> [T] {
        return (0 ..< JNI.api.GetArrayLength( JNI.env, self )).map {
            let element: jobject? = JNI.api.GetObjectArrayElement( JNI.env, self, $0 )
            defer { JNI.DeleteLocalRef( element ) }
            return block( element )
        }
    }
}

//// Passing arbitrary arrays and dictionaries of objects will have to wait for swift 4 I guess
//// https://github.com/apple/swift-evolution/blob/master/proposals/0143-conditional-conformances.md#extending-protocols-to-conform-to-protocols
//
//extension Array: JNIObjectProtocol where Element: JNIObjectProtocol {
//    public func localJavaObject( _ locals: UnsafeMutablePointer<[jobject]> ) -> jobject? {
//        return JNIType.toJava( value: map { JNIType.toJava( value: $0, locals: locals ).l }, locals: locals ).l
//    }
//}

extension JNIType {

    private static var java_lang_StringClass: jclass?

    public static func toJavaArray<T>( value: [T]?, locals: UnsafeMutablePointer<[jobject]> ,
                                       block: (_ value: T, _ locals: UnsafeMutablePointer<[jobject]> ) -> jvalue ) -> jvalue {
        var array: jarray?
        if let value: [T] = value {
            for i in 0 ..< value.count {
                var sublocals = [jobject]()
                let element: jobject? = block( value[i], &sublocals ).l
                if array == nil {
                    if element == nil {
                        break
                    }
                    let elementClass: jclass? = JNI.GetObjectClass( element, &sublocals )
                    array = JNI.api.NewObjectArray( JNI.env, jsize(value.count), elementClass, nil )
                }
                JNI.api.SetObjectArrayElement( JNI.env, array, jsize(i), element )
                for local in sublocals {
                    JNI.DeleteLocalRef( local )
                }
            }

            // zero length lists of Strings are allowed
            if value.count == 0 && T.self == String.self {
                JNI.CachedFindClass( "java/lang/String", &java_lang_StringClass )
                array = JNI.api.NewObjectArray( JNI.env, 0, java_lang_StringClass, nil )
            }
        }

        if ( array != nil ) {
            locals.pointee.append( array! )
        }
        return jvalue( l: array )
    }

    public static func toJava( value: JNIObjectProtocol?, locals: UnsafeMutablePointer<[jobject]> ) -> jvalue {
        return jvalue( l: value?.localJavaObject( locals ) )
    }

    public static func toJava( value: [JNIObjectProtocol]?, locals: UnsafeMutablePointer<[jobject]> ) -> jvalue {
        return toJavaArray( value: value, locals: locals ) { toJava( value: $0, locals: $1 ) }
    }

    public static func toJava( value: [[JNIObjectProtocol]]?, locals: UnsafeMutablePointer<[jobject]> ) -> jvalue {
        return toJavaArray( value: value, locals: locals ) { toJava( value: $0, locals: $1 ) }
    }

    public static func toSwift<T: JNIObjectInit>( type: T.Type, from: jobject?, consume: Bool = true ) -> T? {
        guard let from: jobject = from else { return nil }
        defer { if consume { JNI.DeleteLocalRef( from ) } }
        return T( javaObject: from )
    }

    public static func toSwift<T: JNIObjectInit>( type: [T].Type, from: jobject?, consume: Bool = true ) -> [T]? {
        guard let from: jobject = from else { return nil }
        defer { if consume { JNI.DeleteLocalRef( from ) } }
        return from.arrayMap { T( javaObject: $0 ) }
    }

    public static func toSwift<T: JNIObjectInit>( type: [[T]].Type, from: jobject?, consume: Bool = true ) -> [[T]]? {
        guard let from: jobject = from else { return nil }
        defer { if consume { JNI.DeleteLocalRef( from ) } }
        return from.arrayMap { toSwift( type: [T].self, from: $0, consume: false ) ?? [T]() }
    }

    public static func toJava( value: JNIObjectProtocol?, mapClass: String, locals: UnsafeMutablePointer<[jobject]> ) -> jvalue {
        return jvalue( l: value?.localJavaObject( locals ) )
    }
}
