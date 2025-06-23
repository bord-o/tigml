module A = Absyn

type typecheck_err =
  [ `ArrayNotTypeArray of A.exp
  | `ArraySizeNotInteger of A.exp
  | `ArrayTypeNotFound of A.exp
  | `ArrayTypeTranslationNotFound of string * A.pos
  | `AssignmentTypesDontmatch of A.exp
  | `BreakUsedOutsideOfLoop of A.pos
  | `CantAccessFieldOfNonRecordVariable of A.exp
  | `CantAccessSubscriptOfNonArrayVariable of A.exp
  | `CantDeclareNonReferenceVariableNil of A.exp
  | `CantReassignForLoopVariable of A.exp
  | `CantTreatRelopAsBinop
  | `CantTreatBinopAsRelop
  | `DeclarationProducedNoIR
  | `ExpectedFunctionFoundVar of A.exp
  | `ExpectedVariableGotFunction of A.exp
  | `ForLoopBodyReturnsValue of A.exp
  | `ForLoopIndexesNotIntegers of A.exp
  | `FunctionArgumentWrongType of A.exp
  | `FunctionNotFound of A.exp
  | `FunctionResultAnnotationNotFound of A.pos
  | `FunctionTypeAnnotationDoesntMatchExpression of A.exp
  | `IfExpBranchTypesDiffer of A.exp
  | `IfExpTestNotAnInteger of A.exp
  | `IllegalCycleInTypeDec
  | `IfWithoutElseBranchMustBeUnitType of A.exp
  | `InvalidStaticLinkTraversal
  | `DuplicateNamesInRecursiveTypeDec
  | `InvalidOperation of A.exp
  | `NameTypeTranslationNotFound of string * A.pos
  | `NoDeclarations
  | `RecordFieldDoesntExist of A.exp
  | `RecordFieldNamesAndTypesDontMatch of A.exp
  | `RecordFieldNamesDontMatch of A.exp
  | `RecordFieldTypesDontMatch of A.exp
  | `RecordTypeNotFound of A.exp
  | `RecordTypeNotRecord of A.exp
  | `RecordTypeTranslatinoNotFound of string
  | `SubscriptMustBeInteger of A.exp
  | `SubscriptNonArrayAndNonIntegerIndex of A.exp
  | `StaticLinkShouldNotBeInReg of Frame.frame
  | `UnexpectedNumberOfArguments of A.exp
  | `UnknownFunctionDecArgType
  | `Unimplemented
  | `VariableNotFound of A.exp
  | `VariableTypeAnnotationDoesntMatchExpression of A.exp
  | `VariableTypeAnnotationNotFound of A.pos
  | `WhileBodyNotUnit of A.exp
  | `WhileTestAndBodyWrongType of A.exp
  | `WhileTestNotInt of A.exp
  | `WrongNumberOfFields of A.exp ]
[@@deriving show]
