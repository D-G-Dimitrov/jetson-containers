from jetson_containers import update_dependencies
from jetson_containers import CUDA_VERSION
from packaging.version import Version

def torchao(version, pytorch=None, requires=None, default=False):
    pkg = package.copy()

    pkg['name'] = f"torchao:{version.split('-')[0]}"  # remove any -rc* suffix

    # Add pytorch as direct dependency
    if pytorch:
        pkg['depends'] = update_dependencies(pkg.get('depends', []), f"pytorch:{pytorch}")

    if requires:
        pkg['requires'] = requires

    if len(version.split('.')) < 3:
        version = version + '.0'

    pkg['build_args'] = {
        'TORCHAO_VERSION': version,
    }

    builder = pkg.copy()
    builder['name'] = builder['name'] + '-builder'
    builder['build_args'] = {**builder['build_args'], 'FORCE_BUILD': 'on'}

    if default:
        pkg['alias'] = 'torchao'
        builder['alias'] = 'torchao:builder'

    return pkg, builder


package = [
    torchao('0.12.0', pytorch='2.8', requires='>=36', default=(CUDA_VERSION >= Version('12.6'))),
    torchao('0.13.0', pytorch='2.9', requires='>=36', default=(CUDA_VERSION >= Version('12.9'))),
    torchao('0.14.0', pytorch='2.9', requires='>=36', default=(CUDA_VERSION >= Version('13.0'))),
]

