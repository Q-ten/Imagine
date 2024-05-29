import numpy as np


class NormDist:
    def __init__(self, mean=0, sd=0):
        if isinstance(mean, (int, float)) and isinstance(sd, (int, float)):
            self.mean = mean
            self.sd = sd
        else:
            raise ValueError('Can only create NormDist with numeric input.')

    @staticmethod
    def init(means, sds):
        if len(means) == len(sds) and len(means) >= 1:
            nds = [NormDist(0, 0) for _ in range(len(means))]
            for i in range(len(means)):
                nds[i].mean = means[i]
                nds[i].sd = sds[i]
            return nds
        else:
            raise ValueError('means and sds must be the same length and not empty.')

    @staticmethod
    def average_cells(nd_cells):
        if not isinstance(nd_cells, list) or not all(isinstance(cell, list) for cell in nd_cells):
            raise ValueError('Must be a list of lists')

        size1 = np.shape(nd_cells[0])
        ok = True
        for i in range(1, len(nd_cells)):
            if not all(isinstance(nd_cells[i], NormDist) for nd in nd_cells[i]):
                raise ValueError('each list must contain an array of NormDists.')

            sizen = np.shape(nd_cells[i])
            if len(sizen) != len(size1) or not all(sizen == size1):
                ok = False
                break

        if not ok:
            raise ValueError('All the arrays in the list must be the same size.')

        len_nd = np.prod(size1)
        cs = NormDist.init(np.zeros(len_nd), np.zeros(len_nd))
        as_nd = NormDist.init(np.zeros(len(nd_cells)), np.zeros(len(nd_cells)))
        for i in range(len(cs)):
            for j in range(len(nd_cells)):
                as_nd[j] = nd_cells[j][i]
            cs[i] = NormDist.average(as_nd)
        cs = np.reshape(cs, size1)
        return cs

    @staticmethod
    def sum_cells(nd_cells):
        if not isinstance(nd_cells, list) or not all(isinstance(cell, list) for cell in nd_cells):
            raise ValueError('Must be a list of lists')

        size1 = np.shape(nd_cells[0])
        ok = True
        for i in range(1, len(nd_cells)):
            if not all(isinstance(nd_cells[i], NormDist) for nd in nd_cells[i]):
                raise ValueError('each list must contain an array of NormDists.')

            sizen = np.shape(nd_cells[i])
            if len(sizen) != len(size1) or not all(sizen == size1):
                ok = False
                break

        if not ok:
            raise ValueError('All the arrays in the list must be the same size.')

        len_nd = np.prod(size1)
        cs = NormDist.init(np.zeros(len_nd), np.zeros(len_nd))
        as_nd = NormDist.init(np.zeros(len(nd_cells)), np.zeros(len(nd_cells)))
        for i in range(len(cs)):
            for j in range(len(nd_cells)):
                as_nd[j] = nd_cells[j][i]
            cs[i] = NormDist.sum(as_nd)
        cs = np.reshape(cs, size1)
        return cs

    @staticmethod
    def plus(a, b):
        if np.shape(a) != np.shape(b):
            raise ValueError('arrays must be the same size.')

        a_mean = [nd.mean for nd in a]
        b_mean = [nd.mean for nd in b]
        a_sd = [nd.sd for nd in a]
        b_sd = [nd.sd for nd in b]

        c_mean = np.add(a_mean, b_mean)
        c_sd = np.sqrt(np.add(np.square(a_sd), np.square(b_sd)))

        return NormDist.init(c_mean, c_sd)

    @staticmethod
    def minus(a, b):
        if np.shape(a) != np.shape(b):
            raise ValueError('arrays must be the same size.')

        a_mean = [nd.mean for nd in a]
        b_mean = [nd.mean for nd in b]
        a_sd = [nd.sd for nd in a]
        b_sd = [nd.sd for nd in b]

        c_mean = np.subtract(a_mean, b_mean)
        c_sd = np.sqrt(np.add(np.square(a_sd), np.square(b_sd)))

        return NormDist.init(c_mean, c_sd)

    @staticmethod
    def times(a, b):
        if isinstance(a, NormDist) and isinstance(b, NormDist):
            if (a.mean / a.sd) < 5 or (b.mean / b.sd) < 5:
                # Basically, if we need the distribution to be far
                # away from zero for this to work. Otherwise, we
                # can't really approximate the convolution as a
                # normal distribution.
                print('Convolving Normal distributions with significant density close to zero. '
                      'Approximation to normal distribution will be poor.')

            c_mean = a.mean * b.mean
            v = a.sd**2 * b.sd**2 + a.sd**2 * b.mean**2 + b.sd**2 * a.mean**2
            c_sd = np.sqrt(v)
        elif isinstance(a, NormDist):
            if isinstance(b, (int, float)):
                c_mean = a.mean * b
                c_sd = a.sd * np.sqrt(abs(b))
            else:
                c_means = [nd.mean * b for nd in a]
                c_sds = [nd.sd * np.sqrt(abs(b)) for nd in a]
                return NormDist.init(c_means, c_sds)
        else:
            if isinstance(a, (int, float)):
                c_mean = b.mean * a
                c_sd = b.sd * np.sqrt(abs(a))
            else:
                c_means = [nd.mean * a for nd in b]
                c_sds = [nd.sd * np.sqrt(abs(a)) for nd in b]
                return NormDist.init(c_means, c_sds)

        return NormDist(c_mean, c_sd)

    def __mul__(self, other):
        return self.times(self, other)

    @staticmethod
    def rdivide(a, b):
        if isinstance(a, NormDist) and isinstance(b, (int, float)):
            c_mean = a.mean / b
            c_sd = a.sd / np.sqrt(abs(b))
            return NormDist(c_mean, c_sd)
        else:
            raise ValueError('right side must be numeric')

    @staticmethod
    def average(as_nd):
        c = NormDist.sum(as_nd)
        c.mean = c.mean / len(as_nd)
        c.sd = c.sd / np.sqrt(len(as_nd))
        return c

    @staticmethod
    def sum(as_nd):
        c_mean = np.sum([nd.mean for nd in as_nd])
        c_sd = np.sqrt(np.sum([np.square(nd.sd) for nd in as_nd]))
        return NormDist(c_mean, c_sd)
