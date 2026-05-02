package claims

// #ModuleRelease — thin wrapper that pairs a #Module with deploy-time
// identity (release name + namespace). Real schema lives in 016 (and uses
// #ContextBuilder to compute #ctx + per-component #names); the experiment
// stays self-contained and only models what the slim render pipeline needs.
#ModuleRelease: {
	#module!:   #Module
	name!:      #NameType
	namespace!: #NameType
	uuid?:      #UUIDType
}
