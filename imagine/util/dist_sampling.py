import numpy as np


def sample_from_gaussians(means, sds, m):
    n = len(means)
    samples = np.empty((n, m))
    for i in range(n):
        samples[i] = np.random.normal(loc=means[i], scale=sds[i], size=m)
    return samples.transpose()


def sample_from_gamma_distributions(shape_params, scale_params, m):
    n = len(shape_params)
    samples = np.empty((n, m))
    for i in range(n):
        samples[i] = np.random.gamma(shape_params[i], scale_params[i], size=m)
    return samples.transpose()

