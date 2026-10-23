# KernelSU package

The mtk-imei-switcheroo directory is the module source tree. The ZIP root
must contain module.prop; the GitHub Actions workflow packages that directory
and bundles the current NVRAM parser scripts.

The build artifact is named mtk-imei-switcheroo-kernelsu. It is a preflight
package with read-only MT6835 record detection, not a claim that the unknown
MT6835 layouts can be safely modified.
