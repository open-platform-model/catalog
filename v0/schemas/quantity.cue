package schemas

import "math"

// #NormalizeCPU normalizes CPU input to Kubernetes millicore format.
//   number: interpreted as whole/fractional cores (2 → "2000m", 0.5 → "500m")
//   string: passthrough, must match millicore format ("500m")
#NormalizeCPU: {
	_in: number | string
	out: string & =~"^[0-9]+m$"
	if (_in & number) != _|_ {
		out: "\(math.Round(_in*1000))m"
	}
	if (_in & string) != _|_ {
		out: _in & =~"^[0-9]+m$"
	}
}

// #NormalizeMemory normalizes memory input to Kubernetes binary format.
//   number: interpreted as GiB (4 → "4Gi", 0.5 → "512Mi")
//   string: passthrough, must match Mi/Gi format ("256Mi", "4Gi")
#NormalizeMemory: {
	_in: number | string
	out: string & =~"^[0-9]+[MG]i$"
	if (_in & number) != _|_ {
		if math.Remainder(_in, 1) == 0 {
			out: "\(math.Round(_in))Gi"
		}
		if math.Remainder(_in, 1) != 0 {
			out: "\(math.Round(_in*1024))Mi"
		}
	}
	if (_in & string) != _|_ {
		out: _in & =~"^[0-9]+[MG]i$"
	}
}
