// RUN: %target-swift-frontend -Xllvm -sil-full-demangle -sdk %S/Inputs -I %S/Inputs -enable-source-import %s -emit-silgen -enable-sil-ownership | %FileCheck %s

// REQUIRES: objc_interop

import gizmo

// Test mangling of Unicode identifiers.
// These examples are from RFC 3492, which defines the Punycode encoding used
// by name mangling.

// CHECK-LABEL: sil hidden @$S8mangling0022egbpdajGbuEbxfgehfvwxnyyF
func ليهمابتكلموشعربي؟() { }
// CHECK-LABEL: sil hidden @$S8mangling0024ihqwcrbEcvIaIdqgAFGpqjyeyyF
func 他们为什么不说中文() { }
// CHECK-LABEL: sil hidden @$S8mangling0027ihqwctvzcJBfGFJdrssDxIboAybyyF
func 他們爲什麽不說中文() { }
// CHECK-LABEL: sil hidden @$S8mangling0030Proprostnemluvesky_uybCEdmaEBayyF
func Pročprostěnemluvíčesky() { }

// <rdar://problem/13757744> Variadic tuples need a different mangling from
// non-variadic tuples.

// CHECK-LABEL: sil hidden @$S8mangling9r137577441xySaySiG_tF
func r13757744(x: [Int]) {}
// CHECK-LABEL: sil hidden @$S8mangling9r137577441xySid_tF
func r13757744(x: Int...) {}

// <rdar://problem/13757750> Prefix, postfix, and infix operators need
// distinct manglings.

prefix operator +-
postfix operator +-
infix operator +-

// CHECK-LABEL: sil hidden @$S8mangling2psopyyxlF
prefix func +- <T>(a: T) {}
// CHECK-LABEL: sil hidden @$S8mangling2psoPyyxlF
postfix func +- <T>(a: T) {}

// CHECK-LABEL: sil hidden @$S8mangling2psoiyyx_xtlF
func +- <T>(a: T, b: T) {}

// CHECK-LABEL: sil hidden @$S8mangling2psopyyx1a_x1bt_tlF
prefix func +- <T>(_: (a: T, b: T)) {}
// CHECK-LABEL: sil hidden @$S8mangling2psoPyyx1a_x1bt_tlF
postfix func +- <T>(_: (a: T, b: T)) {}

infix operator «+» {}

// CHECK-LABEL: sil hidden @$S8mangling007p_qcaDcoiyS2i_SitF
func «+»(a: Int, b: Int) -> Int { return a + b }

protocol Foo {}
protocol Bar {}

// Ensure protocol list manglings are '_' terminated regardless of length
// CHECK-LABEL: sil hidden @$S8mangling12any_protocolyyypF
func any_protocol(_: Any) {}
// CHECK-LABEL: sil hidden @$S8mangling12one_protocolyyAA3Foo_pF
func one_protocol(_: Foo) {}
// CHECK-LABEL: sil hidden @$S8mangling18one_protocol_twiceyyAA3Foo_p_AaC_ptF
func one_protocol_twice(_: Foo, _: Foo) {}
// CHECK-LABEL: sil hidden @$S8mangling12two_protocolyyAA3Bar_AA3FoopF
func two_protocol(_: Foo & Bar) {}

// Ensure archetype depths are mangled correctly.
class Zim<T> {
  // CHECK-LABEL: sil hidden @$S8mangling3ZimC4zangyyx_qd__tlF
  func zang<U>(_: T, _: U) {}
  // CHECK-LABEL: sil hidden @$S8mangling3ZimC4zungyyqd___xtlF
  func zung<U>(_: U, _: T) {}
}

// Don't crash mangling single-protocol "composition" types.
// CHECK-LABEL: sil hidden @$S8mangling27single_protocol_composition1xyAA3Foo_p_tF
func single_protocol_composition(x: protocol<Foo>) {} // expected-warning {{'protocol<...>' composition syntax is deprecated; join the protocols using '&'}}

// Clang-imported classes and protocols get mangled into a magic 'So' context
// to make collisions into link errors. <rdar://problem/14221244>
// CHECK-LABEL: sil hidden @$S8mangling28uses_objc_class_and_protocol1o1pySo8NSObjectC_So8NSAnsing_ptF
func uses_objc_class_and_protocol(o: NSObject, p: NSAnsing) {}

// Clang-imported structs get mangled using their Clang module name.
// FIXME: Temporarily mangles everything into the virtual module __C__
// <rdar://problem/14221244>
// CHECK-LABEL: sil hidden @$S8mangling17uses_clang_struct1rySC6NSRectV_tF
func uses_clang_struct(r: NSRect) {}

// CHECK-LABEL: sil hidden @$S8mangling14uses_optionals1xs7UnicodeO6ScalarVSgSiSg_tF
func uses_optionals(x: Int?) -> UnicodeScalar? { return nil }

enum GenericUnion<T> {
  // CHECK-LABEL: sil shared [transparent] @$S8mangling12GenericUnionO3FooyACyxGSicAEmlF
  case Foo(Int)
}

func instantiateGenericUnionConstructor<T>(_ t: T) {
  _ = GenericUnion<T>.Foo
}

struct HasVarInit {
  static var state = true && false
}
// CHECK-LABEL: // function_ref implicit closure #1 : @autoclosure () throws -> Swift.Bool in variable initialization expression of static mangling.HasVarInit.state : Swift.Bool
// CHECK-NEXT:  function_ref @$S8mangling10HasVarInitV5stateSbvpZfiSbyKXKfu_

// auto_closures should not collide with the equivalent non-auto_closure
// function type.

// CHECK-LABEL: sil hidden @$S8mangling19autoClosureOverload1fySiyXK_tF : $@convention(thin) (@owned @noescape @callee_guaranteed () -> Int) -> () {
func autoClosureOverload(f: @autoclosure () -> Int) {}
// CHECK-LABEL: sil hidden @$S8mangling19autoClosureOverload1fySiyc_tF : $@convention(thin) (@owned @noescape @callee_guaranteed () -> Int) -> () {
func autoClosureOverload(f: () -> Int) {}

// CHECK-LABEL: sil hidden @$S8mangling24autoClosureOverloadCallsyyF : $@convention(thin) () -> () {
func autoClosureOverloadCalls() {
  // CHECK: function_ref @$S8mangling19autoClosureOverload1fySiyXK_tF
  autoClosureOverload(f: 1)
  // CHECK: function_ref @$S8mangling19autoClosureOverload1fySiyc_tF
  autoClosureOverload {1}
}

// <rdar://problem/16079822> Associated type requirements need to appear in the
// mangling.

protocol AssocReqt {}

protocol HasAssocType {
  associatedtype Assoc
}

// CHECK-LABEL: sil hidden @$S8mangling4fooAyyxAA12HasAssocTypeRzlF : $@convention(thin) <T where T : HasAssocType> (@in T) -> ()
func fooA<T: HasAssocType>(_: T) {}
// CHECK-LABEL: sil hidden @$S8mangling4fooByyxAA12HasAssocTypeRzAA0D4Reqt0D0RpzlF : $@convention(thin) <T where T : HasAssocType, T.Assoc : AssocReqt> (@in T) -> ()
func fooB<T: HasAssocType>(_: T) where T.Assoc: AssocReqt {}

// CHECK-LABEL: sil hidden @$S8mangling2qqoiyySi_SitF
func ??(x: Int, y: Int) {}

struct InstanceAndClassProperty {
  var property: Int {
    // CHECK-LABEL: sil hidden @$S8mangling24InstanceAndClassPropertyV8propertySivg
    get { return 0 }
    // CHECK-LABEL: sil hidden @$S8mangling24InstanceAndClassPropertyV8propertySivs
    set {}
  }
  static var property: Int {
    // CHECK-LABEL: sil hidden @$S8mangling24InstanceAndClassPropertyV8propertySivgZ
    get { return 0 }
    // CHECK-LABEL: sil hidden @$S8mangling24InstanceAndClassPropertyV8propertySivsZ
    set {}
  }
}

// CHECK-LABEL: sil hidden @$S8mangling6curry1yyF : $@convention(thin) () -> ()
func curry1() {

}

// CHECK-LABEL: sil hidden @$S8mangling3barSiyKF : $@convention(thin) () -> (Int, @error Error)
func bar() throws -> Int { return 0 }

// CHECK-LABEL: sil hidden @$S8mangling12curry1ThrowsyyKF : $@convention(thin) () -> @error Error
func curry1Throws() throws {

}

// CHECK-LABEL: sil hidden @$S8mangling12curry2ThrowsyycyKF : $@convention(thin) () -> (@owned @callee_guaranteed () -> (), @error Error)
func curry2Throws() throws -> () -> () {
  return curry1
}

// CHECK-LABEL: sil hidden @$S8mangling6curry3yyKcyF : $@convention(thin) () -> @owned @callee_guaranteed () -> @error Error
func curry3() -> () throws -> () {
  return curry1Throws
}

// CHECK-LABEL: sil hidden @$S8mangling12curry3ThrowsyyKcyKF : $@convention(thin) () -> (@owned @callee_guaranteed () -> @error Error, @error Error)
func curry3Throws() throws -> () throws -> () {
  return curry1Throws
}

// CHECK-LABEL: sil hidden @$S8mangling14varargsVsArray3arr1nySid_SStF : $@convention(thin) (@owned Array<Int>, @owned String) -> ()
func varargsVsArray(arr: Int..., n: String) { }

// CHECK-LABEL: sil hidden @$S8mangling14varargsVsArray3arr1nySaySiG_SStF : $@convention(thin) (@owned Array<Int>, @owned String) -> ()
func varargsVsArray(arr: [Int], n: String) { }

// CHECK-LABEL: sil hidden @$S8mangling14varargsVsArray3arr1nySaySiGd_SStF : $@convention(thin) (@owned Array<Array<Int>>, @owned String) -> ()
func varargsVsArray(arr: [Int]..., n: String) { }
