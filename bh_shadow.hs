import Data.List 

data Photon = Photon {photon_x, photon_k :: [Double]} deriving (Show)

camera_r = 100
camera_i = pi/2

cxmax = 5
cxmin = -5
cymax = 5
cymin = -5

nx = 10
ny = 10

kk0 = 10.0

spin = 0.0
rh = 1 + sqrt (1 - spin^2)
max_r = camera_r + 10

dx = (cxmax - cxmin) / nx
dy = (cymax - cymin) / ny

cxs = [cxmin, cxmin+dx .. cxmax]
cys = [cymin, cymin+dy .. cymax]

cpoints = [(x, y) | x <- cxs, y <- cys]

-- Assuming camera far from BH => flat space - Johannsen & Psaltis (2010)
init_photon :: Double -> Double -> Double -> Double -> Double -> Photon
init_photon cr ci x y k0 = Photon xi ki where
    sini = sin ci
    cosi = cos ci

    r = sqrt $ x^2 + y^2 + cr^2 
    th = acos $ (y*sini + cr*cosi) / r
    phi = atan2 x $ cr*sini - y*cosi

    k1 = k0 * (-cr / r)
    k2 = k0 * (cosi - (y*sini + cr*cosi) * (cr / r^2)) / 
         (sqrt $ x^2 + (cr*sini - y*cosi)^2)
    k3 = k0 * (x*sini) / (x^2 + (cr*sini - y*cosi)^2)

    xi = [0.0, r, th, phi]
    ki = [k0, k1, k2, k3]

photons = [init_photon camera_r camera_i x y kk0 | (x, y) <- cpoints]

gcov_schwarzschild_GP :: [Double] -> [[Double]]
gcov_schwarzschild_GP (_:r:th:_) = g where
    r2 = r^2
    b = 1 - (2 / r)
    sth2 = (sin th)^2

    g00 = -b
    g11 = 1
    g22 = r2
    g33 = r2 * sth2
    g01 = sqrt (2 / r)
    g10 = g01

    g = [[g00,g01,0,0], [g10,g11,0,0], [0,0,g22,0], [0,0,0,g33]]

gcon_schwarzschild_GP :: [Double] -> [[Double]]
gcon_schwarzschild_GP (_:r:th:_) = g where
    r2 = r^2
    b = 1 - (2 / r)
    sth2 = (sin th)^2

    g00 = -1
    g11 = b
    g22 = 1 / r2
    g33 = 1 / (r2 * sth2)
    g01 = sqrt (2 / r)
    g10 = g01

    g = [[g00,g01,0,0], [g10,g11,0,0], [0,0,g22,0], [0,0,0,g33]]

conn_schwarzschild_GP :: [Double] -> [[[Double]]]
conn_schwarzschild_GP (_:r:th:_) = c where
    b = sqrt (2 / r)
    br = b * r
    sth = sin th
    cth = cos th
    sth2 = sth^2

    r2 = r^2;
    r3 = r^3;

    ----------------------------------------

    c000 = b / r2
    c010 = 1 / r2
    c001 = c010
    c011 = 1 / (br * r)
    c022 = -br
    c033 = -br * sth2

    ----------------------------------------

    c100 = (r - 2) / r3
    c110 = - b / r2
    c101 = c110
    c111 = -1 / r2
    c122 = 2 - r
    c133 = -(r - 2) * sth2

    ---------------------------------------- 

    c221 = 1 / r
    c212 = c221
    c233 = -cth * sth

    ----------------------------------------

    c331 = 1 / r
    c313 = c331
    c332 = cth / sth
    c323 = c332

    ----------------------------------------  

    c = [[[c000, c001, 0, 0], [c010, c011, 0, 0], [0, 0, c022, 0], [0, 0, 0, c033]],
         [[c100, c101, 0, 0], [c110, c111, 0, 0], [0, 0, c122, 0], [0, 0, 0, c133]],
         [[0, 0, 0, 0], [0, 0, c212, 0], [0, c221, 0, 0], [0, 0, 0, c233]],
         [[0, 0, 0, 0], [0, 0, 0, c313], [0, 0, 0, c323], [0, c331, c332, 0]]]

gcov :: [Double] -> [[Double]]
gcov x = g where
    g = gcov_schwarzschild_GP x

gcon :: [Double] -> [[Double]]
gcon x = g where
    g = gcon_schwarzschild_GP x

conn :: [Double] -> [[[Double]]]
conn x = g where
    g = conn_schwarzschild_GP x

-- Assumes coordinate basis => take advantage of symmetry in the connection
dkdl :: [Double] -> [Double] -> [Double] 
dkdl x (k0:k1:k2:k3:_) = dk where
    c = conn x

    c00 = [c !!i !!0 !!0 | i <- [0..3]]
    c11 = [c !!i !!1 !!1 | i <- [0..3]]
    c22 = [c !!i !!2 !!2 | i <- [0..3]]
    c33 = [c !!i !!3 !!3 | i <- [0..3]]
    c01 = [c !!i !!0 !!1 | i <- [0..3]]
    c02 = [c !!i !!0 !!2 | i <- [0..3]]
    c03 = [c !!i !!0 !!3 | i <- [0..3]]
    c12 = [c !!i !!1 !!2 | i <- [0..3]]
    c13 = [c !!i !!1 !!3 | i <- [0..3]]
    c23 = [c !!i !!2 !!3 | i <- [0..3]]

    dk1 = [-2 * (k0 * (c01i * k1 + 
                       c02i * k2 + 
                       c03i * k3) + 
                 k1 * (c12i * k2 + 
                       c13i * k3) + 
                 k2 * (c23i * k3))
           | (c01i,c02i,c03i,c12i,c13i,c23i) <- zip6 c01 c02 c03 c12 c13 c23]

    dk2 = [c00i * k0^2 + c11i * k1^2 + c22i * k2^2 + c33i * k3^2
           | (c00i,c11i,c22i,c33i) <- zip4 c00 c11 c22 c33]

    dk = [dk1i - dk2i | (dk1i,dk2i) <- zip dk1 dk2]

stepsize :: [Double] -> [Double] -> Double
stepsize (_:x1:_) (_:k1:k2:k3:_) = dl where
    eps = 0.01

    d1 = abs k1 / x1
    d2 = abs k2
    d3 = abs k3

    dl = eps / (d1 + d2 + d3)

step_geodesic_rk4 :: Photon -> Double -> Photon
step_geodesic_rk4 ph dl = phf where
    x = photon_x ph
    k = photon_k ph

    f1x = k
    f1k = dkdl x k

    kt1 = [ki + (dl/2) * fi | (ki, fi) <- zip k f1k]
    xt1 = [xi + (dl/2) * fi | (xi, fi) <- zip x f1x]

    f2x = kt1
    f2k = dkdl xt1 kt1

    kt2 = [ki + (dl/2) * fi | (ki, fi) <- zip k f2k]
    xt2 = [xi + (dl/2) * fi | (xi, fi) <- zip x f2x]

    f3x = kt2
    f3k = dkdl xt2 kt2

    kt3 = [ki + dl * fi | (ki, fi) <- zip k f3k]
    xt3 = [xi + dl * fi | (xi, fi) <- zip x f3x]

    f4x = kt3
    f4k = dkdl xt3 kt3

    dx = [(dl/6) * (f1 + 2*(f2 + f3) + f4) | (f1,f2,f3,f4) <- zip4 f1x f2x f3x f4x]
    dk = [(dl/6) * (f1 + 2*(f2 + f3) + f4) | (f1,f2,f3,f4) <- zip4 f1k f2k f3k f4k]

    xp = [xi + dxi | (xi, dxi) <- zip x dx]
    kp = [ki + dki | (ki, dki) <- zip k dk]

    phf = Photon xp kp

step_geodesic :: Photon -> Double -> Photon
step_geodesic ph dl = step_geodesic_rk4 ph dl

step_photon :: Photon -> Photon
step_photon ph = phf where
    dl = stepsize (photon_x ph) (photon_k ph)
    phh = step_geodesic ph dl
    phf = bound_spherical phh

bound_spherical :: Photon -> Photon
bound_spherical ph = bound_spherical' (photon_x ph) (photon_k ph)

-- Assumes x2 and x3 usual theta and phi
-- Force theta to stay in the domain [0, pi] - Chan et al. (2013)
bound_spherical' :: [Double] -> [Double] -> Photon
bound_spherical' (x0:x1:x2:x3:_) (k0:k1:k2:k3:_)
    | x2 > pi = Photon [x0, x1, 2*pi-x2, x3+pi] [k0, k1, -k2, k3]
    | x2 < 0  = Photon [x0, x1, -x2, x3-pi] [k0, k1, -k2, k3]
    | otherwise = Photon [x0, x1, x2, x3] [k0, k1, k2, k3]

photon_finished :: Photon -> Bool
photon_finished ph = (photon_escaped ph) || (photon_captured ph)

photon_escaped :: Photon -> Bool
photon_escaped ph = escaped where
    (_:r:_) = photon_x ph
    escaped = r > max_r

photon_captured :: Photon -> Bool
photon_captured ph = captured where
    (_:r:_) = photon_x ph
    captured = r <= rh

propagate_photon :: Photon -> Photon
propagate_photon ph 
    | photon_finished ph = ph
    | otherwise = propagate_photon $ step_photon ph
