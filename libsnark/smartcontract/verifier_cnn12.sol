// SPDX-License-Identifier: LGPL-3.0-only
// This file is LGPL3 Licensed
pragma solidity ^0.6.1;

/**
 * @title Elliptic curve operations on twist points for alt_bn128
 * @author Mustafa Al-Bassam (mus@musalbas.com)
 * @dev Homepage: https://github.com/musalbas/solidity-BN256G2
 */

library BN256G2 {
    uint256 internal constant FIELD_MODULUS = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;
    uint256 internal constant TWISTBX = 0x2b149d40ceb8aaae81be18991be06ac3b5b4c5e559dbefa33267e6dc24a138e5;
    uint256 internal constant TWISTBY = 0x9713b03af0fed4cd2cafadeed8fdf4a74fa084e52d1852e4a2bd0685c315d2;
    uint internal constant PTXX = 0;
    uint internal constant PTXY = 1;
    uint internal constant PTYX = 2;
    uint internal constant PTYY = 3;
    uint internal constant PTZX = 4;
    uint internal constant PTZY = 5;

    /**
     * @notice Add two twist points
     * @param pt1xx Coefficient 1 of x on point 1
     * @param pt1xy Coefficient 2 of x on point 1
     * @param pt1yx Coefficient 1 of y on point 1
     * @param pt1yy Coefficient 2 of y on point 1
     * @param pt2xx Coefficient 1 of x on point 2
     * @param pt2xy Coefficient 2 of x on point 2
     * @param pt2yx Coefficient 1 of y on point 2
     * @param pt2yy Coefficient 2 of y on point 2
     * @return (pt3xx, pt3xy, pt3yx, pt3yy)
     */
    function ECTwistAdd(
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt2xx, uint256 pt2xy,
        uint256 pt2yx, uint256 pt2yy
    ) public view returns (
        uint256, uint256,
        uint256, uint256
    ) {
        if (
            pt1xx == 0 && pt1xy == 0 &&
            pt1yx == 0 && pt1yy == 0
        ) {
            if (!(
                pt2xx == 0 && pt2xy == 0 &&
                pt2yx == 0 && pt2yy == 0
            )) {
                assert(_isOnCurve(
                    pt2xx, pt2xy,
                    pt2yx, pt2yy
                ));
            }
            return (
                pt2xx, pt2xy,
                pt2yx, pt2yy
            );
        } else if (
            pt2xx == 0 && pt2xy == 0 &&
            pt2yx == 0 && pt2yy == 0
        ) {
            assert(_isOnCurve(
                pt1xx, pt1xy,
                pt1yx, pt1yy
            ));
            return (
                pt1xx, pt1xy,
                pt1yx, pt1yy
            );
        }

        assert(_isOnCurve(
            pt1xx, pt1xy,
            pt1yx, pt1yy
        ));
        assert(_isOnCurve(
            pt2xx, pt2xy,
            pt2yx, pt2yy
        ));

        uint256[6] memory pt3 = _ECTwistAddJacobian(
            pt1xx, pt1xy,
            pt1yx, pt1yy,
            1,     0,
            pt2xx, pt2xy,
            pt2yx, pt2yy,
            1,     0
        );

        return _fromJacobian(
            pt3[PTXX], pt3[PTXY],
            pt3[PTYX], pt3[PTYY],
            pt3[PTZX], pt3[PTZY]
        );
    }

    /**
     * @notice Multiply a twist point by a scalar
     * @param s     Scalar to multiply by
     * @param pt1xx Coefficient 1 of x
     * @param pt1xy Coefficient 2 of x
     * @param pt1yx Coefficient 1 of y
     * @param pt1yy Coefficient 2 of y
     * @return (pt2xx, pt2xy, pt2yx, pt2yy)
     */
    function ECTwistMul(
        uint256 s,
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy
    ) public view returns (
        uint256, uint256,
        uint256, uint256
    ) {
        uint256 pt1zx = 1;
        if (
            pt1xx == 0 && pt1xy == 0 &&
            pt1yx == 0 && pt1yy == 0
        ) {
            pt1xx = 1;
            pt1yx = 1;
            pt1zx = 0;
        } else {
            assert(_isOnCurve(
                pt1xx, pt1xy,
                pt1yx, pt1yy
            ));
        }

        uint256[6] memory pt2 = _ECTwistMulJacobian(
            s,
            pt1xx, pt1xy,
            pt1yx, pt1yy,
            pt1zx, 0
        );

        return _fromJacobian(
            pt2[PTXX], pt2[PTXY],
            pt2[PTYX], pt2[PTYY],
            pt2[PTZX], pt2[PTZY]
        );
    }

    /**
     * @notice Get the field modulus
     * @return The field modulus
     */
    function GetFieldModulus() public pure returns (uint256) {
        return FIELD_MODULUS;
    }

    function submod(uint256 a, uint256 b, uint256 n) internal pure returns (uint256) {
        return addmod(a, n - b, n);
    }

    function _FQ2Mul(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal pure returns (uint256, uint256) {
        return (
            submod(mulmod(xx, yx, FIELD_MODULUS), mulmod(xy, yy, FIELD_MODULUS), FIELD_MODULUS),
            addmod(mulmod(xx, yy, FIELD_MODULUS), mulmod(xy, yx, FIELD_MODULUS), FIELD_MODULUS)
        );
    }

    function _FQ2Muc(
        uint256 xx, uint256 xy,
        uint256 c
    ) internal pure returns (uint256, uint256) {
        return (
            mulmod(xx, c, FIELD_MODULUS),
            mulmod(xy, c, FIELD_MODULUS)
        );
    }

    function _FQ2Add(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal pure returns (uint256, uint256) {
        return (
            addmod(xx, yx, FIELD_MODULUS),
            addmod(xy, yy, FIELD_MODULUS)
        );
    }

    function _FQ2Sub(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal pure returns (uint256 rx, uint256 ry) {
        return (
            submod(xx, yx, FIELD_MODULUS),
            submod(xy, yy, FIELD_MODULUS)
        );
    }

    function _FQ2Div(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal view returns (uint256, uint256) {
        (yx, yy) = _FQ2Inv(yx, yy);
        return _FQ2Mul(xx, xy, yx, yy);
    }

    function _FQ2Inv(uint256 x, uint256 y) internal view returns (uint256, uint256) {
        uint256 inv = _modInv(addmod(mulmod(y, y, FIELD_MODULUS), mulmod(x, x, FIELD_MODULUS), FIELD_MODULUS), FIELD_MODULUS);
        return (
            mulmod(x, inv, FIELD_MODULUS),
            FIELD_MODULUS - mulmod(y, inv, FIELD_MODULUS)
        );
    }

    function _isOnCurve(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal pure returns (bool) {
        uint256 yyx;
        uint256 yyy;
        uint256 xxxx;
        uint256 xxxy;
        (yyx, yyy) = _FQ2Mul(yx, yy, yx, yy);
        (xxxx, xxxy) = _FQ2Mul(xx, xy, xx, xy);
        (xxxx, xxxy) = _FQ2Mul(xxxx, xxxy, xx, xy);
        (yyx, yyy) = _FQ2Sub(yyx, yyy, xxxx, xxxy);
        (yyx, yyy) = _FQ2Sub(yyx, yyy, TWISTBX, TWISTBY);
        return yyx == 0 && yyy == 0;
    }

    function _modInv(uint256 a, uint256 n) internal view returns (uint256 result) {
        bool success;
        assembly {
            let freemem := mload(0x40)
            mstore(freemem, 0x20)
            mstore(add(freemem,0x20), 0x20)
            mstore(add(freemem,0x40), 0x20)
            mstore(add(freemem,0x60), a)
            mstore(add(freemem,0x80), sub(n, 2))
            mstore(add(freemem,0xA0), n)
            success := staticcall(sub(gas(), 2000), 5, freemem, 0xC0, freemem, 0x20)
            result := mload(freemem)
        }
        require(success);
    }

    function _fromJacobian(
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt1zx, uint256 pt1zy
    ) internal view returns (
        uint256 pt2xx, uint256 pt2xy,
        uint256 pt2yx, uint256 pt2yy
    ) {
        uint256 invzx;
        uint256 invzy;
        (invzx, invzy) = _FQ2Inv(pt1zx, pt1zy);
        (pt2xx, pt2xy) = _FQ2Mul(pt1xx, pt1xy, invzx, invzy);
        (pt2yx, pt2yy) = _FQ2Mul(pt1yx, pt1yy, invzx, invzy);
    }

    function _ECTwistAddJacobian(
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt1zx, uint256 pt1zy,
        uint256 pt2xx, uint256 pt2xy,
        uint256 pt2yx, uint256 pt2yy,
        uint256 pt2zx, uint256 pt2zy) internal pure returns (uint256[6] memory pt3) {
            if (pt1zx == 0 && pt1zy == 0) {
                (
                    pt3[PTXX], pt3[PTXY],
                    pt3[PTYX], pt3[PTYY],
                    pt3[PTZX], pt3[PTZY]
                ) = (
                    pt2xx, pt2xy,
                    pt2yx, pt2yy,
                    pt2zx, pt2zy
                );
                return pt3;
            } else if (pt2zx == 0 && pt2zy == 0) {
                (
                    pt3[PTXX], pt3[PTXY],
                    pt3[PTYX], pt3[PTYY],
                    pt3[PTZX], pt3[PTZY]
                ) = (
                    pt1xx, pt1xy,
                    pt1yx, pt1yy,
                    pt1zx, pt1zy
                );
                return pt3;
            }

            (pt2yx,     pt2yy)     = _FQ2Mul(pt2yx, pt2yy, pt1zx, pt1zy); // U1 = y2 * z1
            (pt3[PTYX], pt3[PTYY]) = _FQ2Mul(pt1yx, pt1yy, pt2zx, pt2zy); // U2 = y1 * z2
            (pt2xx,     pt2xy)     = _FQ2Mul(pt2xx, pt2xy, pt1zx, pt1zy); // V1 = x2 * z1
            (pt3[PTZX], pt3[PTZY]) = _FQ2Mul(pt1xx, pt1xy, pt2zx, pt2zy); // V2 = x1 * z2

            if (pt2xx == pt3[PTZX] && pt2xy == pt3[PTZY]) {
                if (pt2yx == pt3[PTYX] && pt2yy == pt3[PTYY]) {
                    (
                        pt3[PTXX], pt3[PTXY],
                        pt3[PTYX], pt3[PTYY],
                        pt3[PTZX], pt3[PTZY]
                    ) = _ECTwistDoubleJacobian(pt1xx, pt1xy, pt1yx, pt1yy, pt1zx, pt1zy);
                    return pt3;
                }
                (
                    pt3[PTXX], pt3[PTXY],
                    pt3[PTYX], pt3[PTYY],
                    pt3[PTZX], pt3[PTZY]
                ) = (
                    1, 0,
                    1, 0,
                    0, 0
                );
                return pt3;
            }

            (pt2zx,     pt2zy)     = _FQ2Mul(pt1zx, pt1zy, pt2zx,     pt2zy);     // W = z1 * z2
            (pt1xx,     pt1xy)     = _FQ2Sub(pt2yx, pt2yy, pt3[PTYX], pt3[PTYY]); // U = U1 - U2
            (pt1yx,     pt1yy)     = _FQ2Sub(pt2xx, pt2xy, pt3[PTZX], pt3[PTZY]); // V = V1 - V2
            (pt1zx,     pt1zy)     = _FQ2Mul(pt1yx, pt1yy, pt1yx,     pt1yy);     // V_squared = V * V
            (pt2yx,     pt2yy)     = _FQ2Mul(pt1zx, pt1zy, pt3[PTZX], pt3[PTZY]); // V_squared_times_V2 = V_squared * V2
            (pt1zx,     pt1zy)     = _FQ2Mul(pt1zx, pt1zy, pt1yx,     pt1yy);     // V_cubed = V * V_squared
            (pt3[PTZX], pt3[PTZY]) = _FQ2Mul(pt1zx, pt1zy, pt2zx,     pt2zy);     // newz = V_cubed * W
            (pt2xx,     pt2xy)     = _FQ2Mul(pt1xx, pt1xy, pt1xx,     pt1xy);     // U * U
            (pt2xx,     pt2xy)     = _FQ2Mul(pt2xx, pt2xy, pt2zx,     pt2zy);     // U * U * W
            (pt2xx,     pt2xy)     = _FQ2Sub(pt2xx, pt2xy, pt1zx,     pt1zy);     // U * U * W - V_cubed
            (pt2zx,     pt2zy)     = _FQ2Muc(pt2yx, pt2yy, 2);                    // 2 * V_squared_times_V2
            (pt2xx,     pt2xy)     = _FQ2Sub(pt2xx, pt2xy, pt2zx,     pt2zy);     // A = U * U * W - V_cubed - 2 * V_squared_times_V2
            (pt3[PTXX], pt3[PTXY]) = _FQ2Mul(pt1yx, pt1yy, pt2xx,     pt2xy);     // newx = V * A
            (pt1yx,     pt1yy)     = _FQ2Sub(pt2yx, pt2yy, pt2xx,     pt2xy);     // V_squared_times_V2 - A
            (pt1yx,     pt1yy)     = _FQ2Mul(pt1xx, pt1xy, pt1yx,     pt1yy);     // U * (V_squared_times_V2 - A)
            (pt1xx,     pt1xy)     = _FQ2Mul(pt1zx, pt1zy, pt3[PTYX], pt3[PTYY]); // V_cubed * U2
            (pt3[PTYX], pt3[PTYY]) = _FQ2Sub(pt1yx, pt1yy, pt1xx,     pt1xy);     // newy = U * (V_squared_times_V2 - A) - V_cubed * U2
    }

    function _ECTwistDoubleJacobian(
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt1zx, uint256 pt1zy
    ) internal pure returns (
        uint256 pt2xx, uint256 pt2xy,
        uint256 pt2yx, uint256 pt2yy,
        uint256 pt2zx, uint256 pt2zy
    ) {
        (pt2xx, pt2xy) = _FQ2Muc(pt1xx, pt1xy, 3);            // 3 * x
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1xx, pt1xy); // W = 3 * x * x
        (pt1zx, pt1zy) = _FQ2Mul(pt1yx, pt1yy, pt1zx, pt1zy); // S = y * z
        (pt2yx, pt2yy) = _FQ2Mul(pt1xx, pt1xy, pt1yx, pt1yy); // x * y
        (pt2yx, pt2yy) = _FQ2Mul(pt2yx, pt2yy, pt1zx, pt1zy); // B = x * y * S
        (pt1xx, pt1xy) = _FQ2Mul(pt2xx, pt2xy, pt2xx, pt2xy); // W * W
        (pt2zx, pt2zy) = _FQ2Muc(pt2yx, pt2yy, 8);            // 8 * B
        (pt1xx, pt1xy) = _FQ2Sub(pt1xx, pt1xy, pt2zx, pt2zy); // H = W * W - 8 * B
        (pt2zx, pt2zy) = _FQ2Mul(pt1zx, pt1zy, pt1zx, pt1zy); // S_squared = S * S
        (pt2yx, pt2yy) = _FQ2Muc(pt2yx, pt2yy, 4);            // 4 * B
        (pt2yx, pt2yy) = _FQ2Sub(pt2yx, pt2yy, pt1xx, pt1xy); // 4 * B - H
        (pt2yx, pt2yy) = _FQ2Mul(pt2yx, pt2yy, pt2xx, pt2xy); // W * (4 * B - H)
        (pt2xx, pt2xy) = _FQ2Muc(pt1yx, pt1yy, 8);            // 8 * y
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1yx, pt1yy); // 8 * y * y
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt2zx, pt2zy); // 8 * y * y * S_squared
        (pt2yx, pt2yy) = _FQ2Sub(pt2yx, pt2yy, pt2xx, pt2xy); // newy = W * (4 * B - H) - 8 * y * y * S_squared
        (pt2xx, pt2xy) = _FQ2Muc(pt1xx, pt1xy, 2);            // 2 * H
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1zx, pt1zy); // newx = 2 * H * S
        (pt2zx, pt2zy) = _FQ2Mul(pt1zx, pt1zy, pt2zx, pt2zy); // S * S_squared
        (pt2zx, pt2zy) = _FQ2Muc(pt2zx, pt2zy, 8);            // newz = 8 * S * S_squared
    }

    function _ECTwistMulJacobian(
        uint256 d,
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt1zx, uint256 pt1zy
    ) internal pure returns (uint256[6] memory pt2) {
        while (d != 0) {
            if ((d & 1) != 0) {
                pt2 = _ECTwistAddJacobian(
                    pt2[PTXX], pt2[PTXY],
                    pt2[PTYX], pt2[PTYY],
                    pt2[PTZX], pt2[PTZY],
                    pt1xx, pt1xy,
                    pt1yx, pt1yy,
                    pt1zx, pt1zy);
            }
            (
                pt1xx, pt1xy,
                pt1yx, pt1yy,
                pt1zx, pt1zy
            ) = _ECTwistDoubleJacobian(
                pt1xx, pt1xy,
                pt1yx, pt1yy,
                pt1zx, pt1zy
            );

            d = d / 2;
        }
    }
}



// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.6.1;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() pure internal returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point memory) {
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) pure internal returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }
    /// @return r the sum of two points of G2
    function addition(G2Point memory p1, G2Point memory p2) internal view returns (G2Point memory r) {
        (r.X[0], r.X[1], r.Y[0], r.Y[1]) = BN256G2.ECTwistAdd(p1.X[0],p1.X[1],p1.Y[0],p1.Y[1],p2.X[0],p2.X[1],p2.Y[0],p2.Y[1]);
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[1];
            input[i * 6 + 3] = p2[i].X[0];
            input[i * 6 + 4] = p2[i].Y[1];
            input[i * 6 + 5] = p2[i].Y[0];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.6.1;

library GetVK200 {
    using Pairing for *;
    function getvk(uint m1, uint n1, uint32[] memory iinput) public view returns (uint x1, uint  y1) {
        Pairing.G1Point[] memory data = new Pairing.G1Point[](200);
        data[0] = Pairing.G1Point(uint256(0x26bcae1b0b6a606e94d60ba1b541b7c4c88e437bf9edbc73add319ca3b6b516d), uint256(0x148ecfc2af347e9a3dd8bee88301a98028cf60d4b370dcfdf862a9d5c616eae3));
data[1] = Pairing.G1Point(uint256(0x1604a2ea8d3ef4a277eb3892878d6d2698202c53384a95f976b36db73d928bef), uint256(0x041dc0738b4635150f2341d6796cda536362869e9d69fc2e22c43a0206b1935a));
data[2] = Pairing.G1Point(uint256(0x1d7e6307ff3caea045139000ada06a147c5a346e1bdf96f28175f65be9041452), uint256(0x215548c934abb24c05718f5747575ceb11a0e4504e10352e6da31526a9786aa7));
data[3] = Pairing.G1Point(uint256(0x21cfc8e92ca03acf93a0e8e00c170b0dab80a3685a2034e1ef46e28d10bd15b7), uint256(0x146adc98d4b70fe565e76c360193102d29a26a59cb870359a7afee4d16a12e93));
data[4] = Pairing.G1Point(uint256(0x1bf3060563d90265e0984c1a8b3bf1b616f210db727bb364da6d1a004db15435), uint256(0x1532087e89500eea81e9c548a6b1f68939f74fe5239a42aa2fb888365b3b5e44));
data[5] = Pairing.G1Point(uint256(0x0a3449f77aa60c22aceb3edbec5d57b4f1d3230b5f50e2895673eb16263c5b50), uint256(0x2a0bee0d29a85de7d8a809e327c9f426b8f0a3b4137cd00552ac3f2e490c6803));
data[6] = Pairing.G1Point(uint256(0x144e2b73354201dab0a5cbb2176762b643417889e9aac33136943c41e554ef85), uint256(0x0785cf967e22fdcfb1b1d43c49bda69e8e6fb004920492260390eb51abce0caf));
data[7] = Pairing.G1Point(uint256(0x05d74cf86c6c40a8b940b22c617765ba82faf811894fea4cb2d3448fdc2c4656), uint256(0x1e853f2260c2cdcff0505dfeefee55fe0776a67e52e93897d07d16a4a535a78c));
data[8] = Pairing.G1Point(uint256(0x1be9c8871883189d021c6a2991c9d34a3b5da984860b8830a49342c663509867), uint256(0x1a993698d1f946df687fd6c2136f730b21339a19de911dbe9e06664e14964f41));
data[9] = Pairing.G1Point(uint256(0x2f7e4b69d3e25f014a46ebd0f4fd7ceee2389c634a67691f3060d0d0696001f8), uint256(0x040737b333f5f2df4edc5400615f23205d66682c42012fbd20f5d95dfcffe449));
data[10] = Pairing.G1Point(uint256(0x0b9c7c6d24edca9d9d6d35f4ea971fc4e6071694e4bbc81adba9c34f5f862fd4), uint256(0x187023ee41ed2975f48d479688db7b63cc499090bc9b289159ce5c83f9261c57));
data[11] = Pairing.G1Point(uint256(0x220f25056f6ae6960d9b85fc6cb7bbb60bc353d9f7ae252a4f1f6ee27304408a), uint256(0x003e34664f9a9764d5e1ea7a1cb363538bde880c1515fa3d15502bcb5e52ac9b));
data[12] = Pairing.G1Point(uint256(0x182675748f4f8ee5e0bf292923ee8cfc97036c67289fa70dfe5f95684ff42e81), uint256(0x20d027a21549a694ca37b4ea0eb4fef47c9c7dffc38d43e843a3bba8c933f103));
data[13] = Pairing.G1Point(uint256(0x02e5f43039a55baf596b65a3c0e6bb4aa3e2c299dcd86e62a9d9c21332d450af), uint256(0x0f0216fa2eb191b590d8d59912b8cb5b552249ca4678e57bc4d5d23d125b4898));
data[14] = Pairing.G1Point(uint256(0x3036585c2bf058f2a83d3bd1ccfcbfdc924370c4ab491003a8dc98f7c3e20144), uint256(0x2dec026fd2c50a02dab3907f3fd74b1ffbd92677346081a19ab4d9ff0bcb92d5));
data[15] = Pairing.G1Point(uint256(0x28a903180b386497adff0454599f4a59c6fe0ee81714d6e372a6a7f70079d03d), uint256(0x0e2bcbe47bace48ff0de07a47dad16114aec6bbda640d5e4748db1bc95bb3876));
data[16] = Pairing.G1Point(uint256(0x0d9408330efcacd4ac48d0d4291f32df1a69f853e1f2063d72b01afcc7a4c945), uint256(0x02f2faa63d8f2d51aa46e4aacf3efcc67396dd803c21e6dcb646627c5d0aaada));
data[17] = Pairing.G1Point(uint256(0x177b7c6b1d8c3bee87b6d141c7ccd21b8b2faadb6d92b90413b35d24ad35bff7), uint256(0x275c82e05b9dfa25fb0ef807d957d12931659cd28936730de5524051975da5df));
data[18] = Pairing.G1Point(uint256(0x1a7d6b1bcb3929b5725aff70da3f56d6eaf83434545ffb964fcb032e4ca00891), uint256(0x06a9d5fb3820db28bccb537ddd862bd044c56b1dc2ba6d42683627d00a90f47a));
data[19] = Pairing.G1Point(uint256(0x1680de842b6c135e3aea39a8dedc7616d647d8bdda84dbbeba4a0f20c83def7b), uint256(0x02bffad063f602f91c702c77a693cd2b3a7c5f4fa81c5c505d02ee4c83d2c7b7));
data[20] = Pairing.G1Point(uint256(0x1f3ea538781e4613af634a75195be1604ab68701378a7edef4001d73418ccc7c), uint256(0x2ec63a6a77e4fb6b198e2c33829dc901fe30e41f59d911a987582fdaa5e7c312));
data[21] = Pairing.G1Point(uint256(0x1bed1a103ee615bef24c8f8b43f4453db3f41ad09c7f35ebbcab6624e5995307), uint256(0x2203417e9c3d435a0bc8592430272e6c681b2fafcc6ce449a2da2555d3ec6ff8));
data[22] = Pairing.G1Point(uint256(0x2e81eaf8a204b71c064583534548cd078752755b305c388297e1491307504589), uint256(0x2d04ae466f50c8744728e532513294bad3ae2cbf7db969047776a7b46b5071a8));
data[23] = Pairing.G1Point(uint256(0x2aa388b69caa89875240f66f8a6ecef95272bb196bd8ed03641c1fdf982e97f4), uint256(0x0a0637f2e2121c0a1e3928aae7eb8526da02402ed43106d11a774fc64279a892));
data[24] = Pairing.G1Point(uint256(0x2903bec315ad5b4b195b10e4d7f5114029aee44eed340b9b23dd31631e1b605c), uint256(0x1bb3094fd687f279991dd7749c0813acd04802bf1a5f1bfa734568d17c03b2fa));
data[25] = Pairing.G1Point(uint256(0x2497ba9eb423336b4a676bae9241bad54ac471a62cfde4dc7f220e8d4ea3d3de), uint256(0x12f30fb2cf8749be895cad6254b6c8873e8d32ef3e427844225a6ca61633527d));
data[26] = Pairing.G1Point(uint256(0x0bc8474389f4751e4fd1ff622e7659c542dd6f31b52923134064c02eaa165369), uint256(0x1948154b737a8309b38a8a57aad852d4d3ce757fd9b5ddd3f0fe51506f9aa3a0));
data[27] = Pairing.G1Point(uint256(0x092c95306ca5ea569efebbc32d71dc780d775b05876d5509f130b2ab597265d3), uint256(0x22337d7b5a88a4108f5b45c0b22e952813a40ad01b8b6b70f4982440334ff550));
data[28] = Pairing.G1Point(uint256(0x1b90a9a4d82fde68c8a777d437ad0553b8425bc073d467a01fa7f3cfac8e34bb), uint256(0x05da395b40b23697ba927274f1d15258fa65e85081fbcf065e3195e684c38057));
data[29] = Pairing.G1Point(uint256(0x2510b9707a8d177ad350d8fb036f27c44e8d2efebb8ebe28c44607bfe0b573fa), uint256(0x251ce41129981a0506c3aec75f5d562f0b5cfad61642e7289889c66c8c9064ab));
data[30] = Pairing.G1Point(uint256(0x14f8319fbbb5d18af1cd7135958f59d61c3a4eea9d002fcd17b5a87acf5e5e7f), uint256(0x0f4d7bef954d821077371f3e87a83d0be8cb6d4125d47ff1d7c44452306f1531));
data[31] = Pairing.G1Point(uint256(0x1174b6c1af04e322b6b4498b4b863a2e20a7db1c2c4d744ffa123fc6e7bf4079), uint256(0x2aa973c7be447755ef5c8c3ea706523024bccd1061224096e10090f4dec1bc6d));
data[32] = Pairing.G1Point(uint256(0x17dfce35c48eb654a76c005f5f9cd447f8238df5d02052b1c8cfe354aeac81ce), uint256(0x28a436a4ecf2d6207fe95c4386a0fa6a9660d136535d59c8f3db8b1f606bcff4));
data[33] = Pairing.G1Point(uint256(0x15e8a1750082174aacb6b28edeeb2d2d72fd29a649450cf760a9a62594baecc0), uint256(0x07ce090fa9c1387386155425368d603b0d6012238eead3d60c27bfb9966da782));
data[34] = Pairing.G1Point(uint256(0x290cd6be89291e02a29af48c0a63ad2c18f30a9fe0aa7e312e5ddf7ef2c239e8), uint256(0x1d2dea87a7c9e40db61f820ef9e1e2ce013796447144d71f3e22e3cf0dba7af3));
data[35] = Pairing.G1Point(uint256(0x169306b51bd323d7818e8a30431c89ed749e1e08801a31307a5c02cde9f30ecf), uint256(0x217b420f0748ebea389fc3a9bc6b4edf0d15f2ca3136adc3eee4ef7ce6d66edf));
data[36] = Pairing.G1Point(uint256(0x08d2e69b1dc612a919db83e33464ffe8391642afcc62a6482de25a4e5642a0e7), uint256(0x04fadaf155e240b9a272faace04ac63261e5858f5323538469dbde2a98125348));
data[37] = Pairing.G1Point(uint256(0x02c2f37a546bdc8c2de083f78f6930c3f3fc1db01343111741989856b5a85bfb), uint256(0x1cd307d0bd0cc82f621bc7c8ee354509ca5ea61d31915b4d64b99a022607f77f));
data[38] = Pairing.G1Point(uint256(0x228bf24c35c805f2b30f23e4c08995251bd7451f30d826be12f29c657d252700), uint256(0x0ff84408a7a350ae4cf8a4e610d0606f6117e4e2e3f2b2da0e1b2b41f9eea720));
data[39] = Pairing.G1Point(uint256(0x17bdde2b9f472bb109fb0049792d8e7893219efb47118c3b2d88123a0ce5282b), uint256(0x0e7b5adeb6b6949cbaba736409626645fe6d0d0e8113397c8b9af28b934d26dd));
data[40] = Pairing.G1Point(uint256(0x28821932139641ada340d43e5dfd4d93f1693862a43982b7ab60b505b49b7209), uint256(0x131071db502d6d6510a1cdfb59daab65da6225872cd3beda73ffba7840a2b627));
data[41] = Pairing.G1Point(uint256(0x03c9b6d33f7722b0a9faf87fb50e17e641f38956023ce25222a761370f86fe7b), uint256(0x0a5043fed525b9cdba8daedec8d3704046cdd036c9eb55df94305aa5e4393a62));
data[42] = Pairing.G1Point(uint256(0x160e412cbffd88d467ea1e0eccefe5d66bff836b5dd50b0f75bf1ea870d05906), uint256(0x2e991f7948ad1bd852e4e5664a6f7bda500f9093e4500a8919b2580928163bb1));
data[43] = Pairing.G1Point(uint256(0x24fc7c53a43c70454ed0d464fc128c610f23508e6144d392e8789e2285f2d611), uint256(0x13285ef1355eba47bc05166a80c7d391a7e343291ad1f0346e2cc3240c27977d));
data[44] = Pairing.G1Point(uint256(0x2718cf2d07359d994dbc958bc9f021e09a07b57bf713afd851be00d47d9f6125), uint256(0x2107962fb000fd2e61c5c54457669864b1054424f5ddfda6377322fead3ec0d9));
data[45] = Pairing.G1Point(uint256(0x0979406164d55091493b3f841595518d0e5058d5e0449ddab4e2f78ed281531e), uint256(0x25307f3ebe21a8da52c722842d267e0a59c6eb3aa5e2f45c058f7141e86f7ef8));
data[46] = Pairing.G1Point(uint256(0x22a9a8f9b5a3ba0d3d4f8f1225d8c7036ae141822349836b625be03bb148fc56), uint256(0x2498f0014574a1c1afb1b3429af66b059605f368f27c166b8618665aa7588d61));
data[47] = Pairing.G1Point(uint256(0x2b7e2b0d5693e09586dde6a4f1698fae9025995b47d6f8f22e5b67682f114244), uint256(0x0ca410aa5eef2168354e587f0ffb5d2ee28e0aaa8e1358a9d0e08e9420b74af9));
data[48] = Pairing.G1Point(uint256(0x0257b642aca333fce513e55002e7e4b3a42eed2c08a9eea44e5712fff438b123), uint256(0x1aa8bfce6784f5a8dd6f4d371b1998538842ffa21317f2ed2888c945ead52701));
data[49] = Pairing.G1Point(uint256(0x140dea5b3f97fc02df926ee6fa0d38eb225ccc7e1ead30139f449951f953b405), uint256(0x0110d6afd8dfa93af93c0e3e3bfbf6b2eae075a91ebbb765e998f9daa44376b9));
data[50] = Pairing.G1Point(uint256(0x114bdc8b53a65881d84fed305371a7824cf02cb15c17ecfac02e620d9b8a2f73), uint256(0x106aa15059afee0aa182e06ab92cb1722420a98cd42484a7b88bd119649070b8));
data[51] = Pairing.G1Point(uint256(0x0f74b1af7fcd64b5813250b8082e4f61aee2e4954d9c77a213eb4b54feb4e993), uint256(0x1171c44eb06b1047ac96aac56da50abc379bbe777bf688d4dfbdaa5c4b5112a7));
data[52] = Pairing.G1Point(uint256(0x03c631e172c1a84db236dc550011b315dc6a3c1fdcd4d5eeaf7a5334ffca073c), uint256(0x0cc912ff8aa7241a9340e318f9b4b5c67c29c18b0b87981bb7d8d49732b9d995));
data[53] = Pairing.G1Point(uint256(0x08c7ecb8f773c031e2564ece1f218b45de17fb35ca78c2b60179ddc2c001a6da), uint256(0x04d84d7daca2b37278befc16aa5a55d65e8d8dc83b36762f8b9860f7a519fcf7));
data[54] = Pairing.G1Point(uint256(0x20f4330a61014954be41bb15f996a4bc6742d431bb4f783ef8f5d5a72a32aa58), uint256(0x2e7d28ab702011cd3764ae2f653e9ccab1ddf6afd5777cbb14b5a35c974484fc));
data[55] = Pairing.G1Point(uint256(0x29f9f463702fe7b3352ec31f564eaef6d9ccc6ada899f0ad5ba5ed28bdf1ea80), uint256(0x0ef7dad87a01276ff8995a9d947e3381f88e09a4daf2d9213e3ad202efd2f352));
data[56] = Pairing.G1Point(uint256(0x2b1913733f8ac410e6430d9cc06cf2b4927bebd7512dcbe474b2e036f4a823e0), uint256(0x1a10b1545aecde083ea8ee893b24b67d7aeb4a3faf07be05f961ceeb0f527d75));
data[57] = Pairing.G1Point(uint256(0x2edd8f5fd2b709fc68b9907eb139a57548d961dd7fda3087f0d0758e9dca7d0f), uint256(0x0abf44d5b13e3ddd2fff3424ce795e180345373bfb574f7e3e2832ad9d453f3f));
data[58] = Pairing.G1Point(uint256(0x0b7b283ac96f00497465eddbc1b17b1330e4afbbce14ce389a86b04b53696dc0), uint256(0x0632fb6a12ce3cb591791f07e58fbd1e11315d26541eb1ebf76bbd2791985b4c));
data[59] = Pairing.G1Point(uint256(0x2f284e410314166f5f8ba727c4f41a1c23c6a0441eb93169ceeb3ef4a08d80f0), uint256(0x0f875cd73c890905861fd4be042eae159417b066bd8be566c55aeb6eba525f18));
data[60] = Pairing.G1Point(uint256(0x25ee802d42d2f59ac310b7a500e4b739956a5393ddfe0a841edf5eeafd5448c9), uint256(0x177b24929882cba2cd8b90d63e196bc7cdc3fccf7b72835923f212cd37d3fa71));
data[61] = Pairing.G1Point(uint256(0x0dc18bb22fcbb6fd804603afd0b901aa094b161ed5d324563f1bb8bde5949fa1), uint256(0x15cbfee9dae27b72e0f7da4fd61113fcf6bf0a16fd00ad64082fdad40cae6e20));
data[62] = Pairing.G1Point(uint256(0x2edf2ee9b64f14fed354f8872cec4a4472be6b4f6b99b490bd7630e7cf38e0a8), uint256(0x3001da570b70bf3e12a747db8414fae6b24c6c961db5d91c3f40b63ea82ff954));
data[63] = Pairing.G1Point(uint256(0x1c6fe1b1ad189ab2b6141b977212a29f71997b538c6ca673e077d18f2b2a897c), uint256(0x14c2345dbd9b622a06c20d386343d6003feda1577cb4d1ef40077697813b5c24));
data[64] = Pairing.G1Point(uint256(0x2dfc5563e822ccd5345f4714aa8312598a27fde9c9e86385cb2408f20d22167c), uint256(0x1dd2ea652c813236750b70f17f482b47e568ac3914af66ef7a60cd823d14cd38));
data[65] = Pairing.G1Point(uint256(0x1d3552810e79a5032df0f609dd8b485b18d61168c4f51517b79ce434daefe5b4), uint256(0x2dadfd9baa0b49f55b940b482fd0c61a466edde1d69e95e6885a1b41fcc4a1af));
data[66] = Pairing.G1Point(uint256(0x237bf4409142628c22a03ef84b6e98799cfa2b225a2f496b50e23b13e6083731), uint256(0x099adbb723b00a8cf9797d662d6d6f94ea70ed79396e194c81a8ad3594914702));
data[67] = Pairing.G1Point(uint256(0x29c8b46ea67207a869b7aa41ef76a6699b39057d551533bc09a1a130236fba8c), uint256(0x1e25bdc030a160159647f741e69e4b41f9b7540790fdc6733ed47b35a10fb741));
data[68] = Pairing.G1Point(uint256(0x1c05cb4791d070c57cfa80aea1eefb49bc82721250c975effeadfbafdd284d94), uint256(0x1341db34839ce1f55ff6446f1addeca3daec213453fa52977aa0df45bafc499f));
data[69] = Pairing.G1Point(uint256(0x16598862f52d0abedff0232b43a50edbabfe5495ca7f8d2e6451f01c711a9e68), uint256(0x0b72c30060146b7f9059ddbdfca5606d7769186a2ae22855de7f78def031db72));
data[70] = Pairing.G1Point(uint256(0x2bd5c8c70f81b797424ebc644bf3d23b1f5c7f3bb877652d67e5c7eeec45c7a9), uint256(0x01fd0409267c5afc104ebf4b1441794258b739f0319f1476f5b08c8d56567301));
data[71] = Pairing.G1Point(uint256(0x120226d8ce957d864bb57ff072e98383d46f977aea03d41d94289063111f7ac5), uint256(0x2c8eba1eda9d2ac929dbc7ddc008bac8173d0eba68c1c1672ec39d9ce64066c3));
data[72] = Pairing.G1Point(uint256(0x19beccf5e7a0f810f77a71b19e12f225902e5528167a7f08b44f77c7b46c032a), uint256(0x2e5a6f3f735bfccf7b218783f2d36dacf5261664ffa1d424c2e96fdec94e354b));
data[73] = Pairing.G1Point(uint256(0x1991f58a59884e85e10ceb720373cb43eeeec295ccf8ebd85988fde7f50fe98a), uint256(0x2155c729a3a8e533097e31d53ab5dfd7a2e22e25b6310751315f9c6302579921));
data[74] = Pairing.G1Point(uint256(0x070fc580d09eb34a1b2f364e9a2ef58d95f924624e5352195530438725192e43), uint256(0x2443ea2801662a3f4afa4d061dec05b0c9419f023ddcf865601eb7cfc3e73dfe));
data[75] = Pairing.G1Point(uint256(0x1318f870c0e446a0f4789a591f6b6de2289e6f9ac42c3eb7f01e22784acf5e88), uint256(0x04ecbf425d70693e386a6538f00badc83ccdb3837fb64d7b91b6f11e331652c3));
data[76] = Pairing.G1Point(uint256(0x10514a9bd2299f7b6aed702caef5c09c7f232e3895d2cc1a456da0cf3a16a9d0), uint256(0x2af7adc00cdbed0785df179bae543d6e59b83f9293c25c6cfeb9a2f115762d64));
data[77] = Pairing.G1Point(uint256(0x2511d78862a5521059a54a862c2dc5a160123a97422de8822acaa2cc9f6dce77), uint256(0x03176841d82fcb1d0aa22552112f0a7ef74f307d7cb9e759a35a4d094757c09e));
data[78] = Pairing.G1Point(uint256(0x09186c4e73a819cf957cd296cd72b13a4f42a82eeba7f6deb5915c9b05b0a19c), uint256(0x04f318bb96444e55a8c91e794617744ed92e4ff219a5e911800089b29e3416f0));
data[79] = Pairing.G1Point(uint256(0x2824b2d1772b10f6e8aa3fdcfa36c0cab3b6a8e052b2d604915224a041119dea), uint256(0x01689157a83ad66e61b241ad98918ba46f2c733936f8fa472fe56df153b5dce3));
data[80] = Pairing.G1Point(uint256(0x000f6b3b1ae6282bba94002a30c83eadea2e484c530e662130f3f4ce410c8907), uint256(0x0a4f5981e358a88389834f9b5c1f4c23d1700e5f2ef83386ac48786c2f19b75e));
data[81] = Pairing.G1Point(uint256(0x29553de4e9168f4ea450c5a3856f73791de100de583394c45b6e7d2356f9c923), uint256(0x16c4b6541db5a8f41822a2dd54f542e5b4dc61321bbddc4a3b197f8c25530333));
data[82] = Pairing.G1Point(uint256(0x2012249928457fb8ce5af4a641d18649e1dd4c4a3733ad50b892c4f0df3bbf74), uint256(0x0512ecbe62894d033875346ca9924251928b1d96603f918b7e727f6b8de493f3));
data[83] = Pairing.G1Point(uint256(0x16e218f5059d0601702f2787311df185c54bb9c0e57fcb4a3dc8c2cfef47ece9), uint256(0x2524f9b4f63db74db91739d91268b5d4024d4a1b10a47ab50620674f719c075b));
data[84] = Pairing.G1Point(uint256(0x09e8c048e529f998b882af4683a86b0dc54b5ada4e562d3a8c4f8c1e948eac03), uint256(0x116a8f222cf822bfd797a69cff939c24b68bc2ccfd70fcda2f74edfc6099bf76));
data[85] = Pairing.G1Point(uint256(0x2c24ff9591a074509515604c8114babed374684224ad2dee423a0d803249c5cf), uint256(0x0871de9adbe68a4f5bac209c5c3ef5e2208af1b84e61360ace057969b4d864b7));
data[86] = Pairing.G1Point(uint256(0x27001c0d40719cf0f76a13220b1ce5faadcbe5a493c2367d2c509f5a71980a2d), uint256(0x2ba8b62b1bdfaec0fd9242c26fd97f7f6016fe5f10c87696152d713b299480e3));
data[87] = Pairing.G1Point(uint256(0x21f4cbab2f4c94b9afacfc5c865bbe568c5d882b0ccbbce0e5d402b831107d4a), uint256(0x0a359f98f837febb8ffd37648062ce585cfc16a7d16994c9ee48a36e045cc352));
data[88] = Pairing.G1Point(uint256(0x0a40bea1f83c9f6027c56bd605c8208d3e8e4ad73f569a472bc8f1d7fe0eb21d), uint256(0x04ab32f6eeb03ae1236b78db93b1b0c6fba1b6519f68552bff06a39063762677));
data[89] = Pairing.G1Point(uint256(0x01d653b935fca0b9049914ba240e6d3496605fccc888ef809d7666583c2ac499), uint256(0x07641976b4b031092b3c05b3f3a60163cb9fd276bd4281eebc0a257a38804137));
data[90] = Pairing.G1Point(uint256(0x0c3c86dced6df47a2d83502e90925a1bf8d9fbc815bede98b9643dec46ce32a3), uint256(0x1b301f6538de39dbbf8a5927a6bdebf8bdaa9ef46bdbfcba776ba2bf623c8e3a));
data[91] = Pairing.G1Point(uint256(0x23e2a312567a388322191ab9ef2f8af5937a708dd5c61fdae0c304579fe15dce), uint256(0x13a2708a833bfd1ded438d84c6363bdf98342dc550e5392281b032ee94dbd9d4));
data[92] = Pairing.G1Point(uint256(0x13cb258c140c8382479b85f58ececd1962319a1206d48d4a7b5c5da32eb64b23), uint256(0x15faffd12e274a16ec5c4749371196d6ea260f188789ef1599f6188adcabe12d));
data[93] = Pairing.G1Point(uint256(0x2b9cdf3790b8d7c67ceaa7f99053202b8e1fe7b5a56e2f8b8924ea27c576cd6a), uint256(0x016b6e20d4764b3f43e9fd9a9356a50796cf9f17e1d3df10d81e28c3bec1c18e));
data[94] = Pairing.G1Point(uint256(0x0a9b6f9fe9892a1108b7f63711e5020f112a4162c0fbe6558c332722b4e403b0), uint256(0x2f1897963f913f8fab68a6412040d80e6dfd1de8b7dd086bc7d7b69105e39d86));
data[95] = Pairing.G1Point(uint256(0x194e24cd73ba6774616b6074b30d70b9c37f3bac099c29d7e5dd811f1b360f6e), uint256(0x2a5292bda6b3aef926537c3c542b5609a1b341aa57340826eef748a7df26cb0a));
data[96] = Pairing.G1Point(uint256(0x1ea4a4807de8e811eed71330a1ca0d4e394f0f899634b44b3b79a95b747f84b1), uint256(0x212cbc31ffaee8d794ba9cad3faf3dc9dd3ebf362c292070060fa24e74d58781));
data[97] = Pairing.G1Point(uint256(0x0f29b69d709c44c325a752a93e3a09620dc22d311b24b45643ab5f28d2b5d805), uint256(0x3029f00cad57862bf3050a6edba77ecb418fbef3cbfca73f236786a87de5ecbf));
data[98] = Pairing.G1Point(uint256(0x1ca2eb0e6dbdad684a88b6d824647454422c5ba4f079aae2f55c9f26e111b36a), uint256(0x0f1ee4770b6a25a3a49d0dbe9c11097191e195b98e677bb8ab5b00c2a98a4a97));
data[99] = Pairing.G1Point(uint256(0x24ec79e68e4d26bec57eb7c6dd9c122d9502f571168d607ebf23919dc560fe34), uint256(0x0165a2d904fb554fb48c101625df697c79c1d985d0af1bbd74806d8dede99ab0));
data[100] = Pairing.G1Point(uint256(0x25b8684524db3cae33c30c9bc560ec73703cdaa5961a74dbc4e348439b23b250), uint256(0x2432e2e1f9c1aab8c99feed043a73170483df62e1324a95deb0d8f4855fad41d));
data[101] = Pairing.G1Point(uint256(0x22350e4c71b7406f87e2753b987039f020a763a294556fa6f4ddf3df1d9095ae), uint256(0x2187dc029418871008b9cb0c5ce2f526db9977ffefb697259e252971397e56b4));
data[102] = Pairing.G1Point(uint256(0x1b316f41318fc7f1e5be9d94cc2233ce0a53f638f17837f4d49d4412b740f595), uint256(0x140c0a59fdf2c6b41ef20a48a3f26ae199d7535e9cdb1de3fd9534c2214ab5ad));
data[103] = Pairing.G1Point(uint256(0x0a46ce9c55dc49939efa9436aa49b51136a74cf4f1a8938f9e569e294f2f73b6), uint256(0x089aeb373f5b2a07962bcfeedd295b9a0b90b6eee0fe0d3cb2a4061aa6ceb98a));
data[104] = Pairing.G1Point(uint256(0x2e7e8379c9850a7893fe87e726c5d5607b70ce0fbd788f0916ed300e034bc694), uint256(0x2c0b6b8758b391339e08676a342ba084cdac4269756c7d0068bc9bf71ca69e73));
data[105] = Pairing.G1Point(uint256(0x2b0209b4d6bcfa8fbb72bb0034023136588ee7b1c66e61520d600263d72d02f1), uint256(0x2e955568d287eae9740ed9736081d892747e119bb3c570179bbd12b079e9da38));
data[106] = Pairing.G1Point(uint256(0x19b9a88169c96a32774a5812a6968a063f91aa561ff5c2f8bc05fe719d6ed23c), uint256(0x0689531e56d8e4670e2246c342d83e3d848dc6d0199deb28d8443feaaf7684b9));
data[107] = Pairing.G1Point(uint256(0x20b93b8fa85b711621f93255fec78460b548d8f5daa0e194f49167ed43321b13), uint256(0x0760e6ab9703101948b77d4bc5d4fdc6ff46b1621e0c6e40b003891f9feb48e6));
data[108] = Pairing.G1Point(uint256(0x0b93e69cfe8499389299bcc3f04e0fcdeed809e0be198ac5a89f8eba61a429a6), uint256(0x0221cb5e1dc90f943302df8ed668dd7dff075fc77a9fb0d8685ad07c60a96755));
data[109] = Pairing.G1Point(uint256(0x0d739331595d2a312fcac8601f4301a6939c52e3b2aa894214f5683f88055bc3), uint256(0x2fc114ec16a0be84c2e7bbc35999836f729e7d98460ceb2b9d6314d67ca48af9));
data[110] = Pairing.G1Point(uint256(0x19b47670229dc054afe8a391899ed79a536914a86ad24c49d3990be66eed2d70), uint256(0x2227d2f5338569e7676b76bd308328e5d83f2b5324b7016b81753406b3609dc0));
data[111] = Pairing.G1Point(uint256(0x09f76e5105f7cd73c39b8e3b15329957a0bc4b9aff5e02546759eeace4ed506c), uint256(0x1a12fc8eaabcac541a939922a4b0a953d684ca7c9737d416233e6b96d93c468d));
data[112] = Pairing.G1Point(uint256(0x0f62a0b0386e794e0c6f3622d13049dccb5c0e26eae788ca1e6f37240941fe60), uint256(0x07841cbde761d490d1c3bab10139a6c1bf8df8599a25a4a5e1974b2bbe9b7b6b));
data[113] = Pairing.G1Point(uint256(0x0f97e3a91f495c0688b60008db79f27d10f2f4ffc0eb8bf4b84f75b48cabd415), uint256(0x0579edf4bd3ffb8cc2c9b0a603ee453de0df7c25c2c7161f9e7c26f5ef9e5534));
data[114] = Pairing.G1Point(uint256(0x061d503fe3926f9adf9ff617b667bb10845fdd11eca5b129307acb81da05654f), uint256(0x25f8fd3e8e513e6b77a9f7aa72d126794c6e96d524a034d1b9f1d99168ae2d54));
data[115] = Pairing.G1Point(uint256(0x2ae91fedf04e9487f03e40626e43a3ee0d74510c8b4c1e5bcef236986c6a83b2), uint256(0x200266820e35b4ff295ea7227dcb18866db9f2fcb6c15946a34dd4fcd484ecb1));
data[116] = Pairing.G1Point(uint256(0x1baf44d350ba7a4e046209b7041a3632097d229308d15a30ab05b0a3340b174a), uint256(0x2c5bb7f294c31a6321b6572dcce6c018556428f3decd4cfdb65b96518b134c8e));
data[117] = Pairing.G1Point(uint256(0x224759dd65e7827fd12be74723e8f7f7fc5d7648b59d9fce55e969ca3c4bd102), uint256(0x11babd05ae642b66bd9c8c2e90c91159c64fb7bbda48b4dd45574c81b16732dd));
data[118] = Pairing.G1Point(uint256(0x30507d793165e8a9ef66aed94dab7ba882cfc841746ac847549f1825fdd39399), uint256(0x2fe93c4827d027d71d7731b974ae0755e44041b0bca08459ef3892dfbcda9dcb));
data[119] = Pairing.G1Point(uint256(0x1c9b27d2f4b5099330fc90b0ec1c90978097aba88e4eacee72cc116e40cee983), uint256(0x2dcd068ce0632864fb5a52717a948d8f2c75be981a6fe9ef57e34f979a2e7756));
data[120] = Pairing.G1Point(uint256(0x275d9f7e1855d0885a68efa83d4fec1bf7a4abb17a26cbece8e44590ede7cbfa), uint256(0x28da4ddd216fdfb34ebe4b643ef37029de14a847e159068b6c8ac2802328838b));
data[121] = Pairing.G1Point(uint256(0x2957fb09777406cc5f4461544a0049e35499ee56c4786959c166207e1e9c5668), uint256(0x06d68d4a2804cff75178db30392734e5aa05c1bf5126b76f5c4018e1ffb7297d));
data[122] = Pairing.G1Point(uint256(0x12a49c8affd5264e32729c24a3383817238455c6e177ffff85cdb2b382f4fca4), uint256(0x0545fcf2be67df18d3c24de5459640809fa534c81e470c360948f0b334101f7e));
data[123] = Pairing.G1Point(uint256(0x193ff606d449115f8d6d15778e1814a3054a2565a07e9a1a39005fd0664f4710), uint256(0x13855cefa1774b25f8a7c7bd539edee7f61cf76fb378300d06cd976155ff838d));
data[124] = Pairing.G1Point(uint256(0x298ce7764f15018d54f63a8e7001dd20b40962c9a0430f35d1f9eed8eb320fdb), uint256(0x0cca4f3faf34f0221417cc41a0348186417d8c14bee168dad3408706b3e96f5a));
data[125] = Pairing.G1Point(uint256(0x264cc1b3ee9ee2275d82da6da1a86a4e166634a133a7facc646725f6cceee395), uint256(0x1dfca4adec542b10b7df2b75d044463bdd52b8648ffc8de3dfb1f1071d42053c));
data[126] = Pairing.G1Point(uint256(0x26dbc1849b16fca7e02068a097c660f28f54bf76058f9cee6721c9f1bab10399), uint256(0x1056dc5fc382b16a820163cec137c26d7d2521300929836d9f508df64f3d6cff));
data[127] = Pairing.G1Point(uint256(0x0b383297b6d512d366c0b627553d2de12e4ee4624674a05cf33a3a43d8127074), uint256(0x2c5e5f63cf5e796464251e7d6d0f8004d638cfbecf4887051cd6fd20a055025a));
data[128] = Pairing.G1Point(uint256(0x2df3de9f76e6ec1743797cb1724b1f355719029e2a19c660796283e3422100c8), uint256(0x106115901a28acbb9e0e1962034fd1059a996461c7affeb39a128464bd7824e4));
data[129] = Pairing.G1Point(uint256(0x074e63cb1f38e7235ef3da07502c489d130d2b2149137ab85e67cf2e8294d406), uint256(0x0069016f3b91642ef6767239685a3e62a193fe3cc009058c7ba37bc91cc6c507));
data[130] = Pairing.G1Point(uint256(0x00ed9965724b4604fbe1b4e2148eec5c3f60624eed52b5074e247663b937c419), uint256(0x01dfa80d8d1c1e7aba62279452cc1a96a5b5487127a1875c7dc9961f3ffc4cb2));
data[131] = Pairing.G1Point(uint256(0x0a4a7a2322258bed589adaf39523f98b724acbc0d51be9139f662b9ebbe3ebe3), uint256(0x17cf6908088d28e881fb8629bde450adc43ffd77b1a6e8207ae9bbfa7facc5de));
data[132] = Pairing.G1Point(uint256(0x10801dca9283b571d0fd9b0f2cd19ef20512fb4970710612cf8837fd556566f5), uint256(0x13b22ba4d37b2c3f3099c887f534765db50b7f0162e1abfcc659b0dcc640909a));
data[133] = Pairing.G1Point(uint256(0x1d117f14c152e189c130170d051232261ceefcd2f905d0927ab79eeccfedd09d), uint256(0x0cc4485b50a14d6555175a3817dbc7c45ab75c9fed4b2b46f7ddd2033a6427c5));
data[134] = Pairing.G1Point(uint256(0x03195263583ebaef3cfaa994e521fda6892c3ce8f73e77d7ae8b1a39e92c91e6), uint256(0x0cd92628c1c497a6d829e0f1af879fbfab4262b738240cd74522e7f9fbe7bc99));
data[135] = Pairing.G1Point(uint256(0x08ed01b298c6d6b9dffe457a9be5dd1498ff0781c66205013a77233d53a17586), uint256(0x23b90d9100698e9064731750c7e45715abb848f49284f8c7c031b20cbdb57564));
data[136] = Pairing.G1Point(uint256(0x0b1708adb14e3689253eadc0ae99f6a2b4f9c67fecf51432f01541c0d1da5391), uint256(0x221e6967d178f1272c74f3918dc6104e4bf5bea15a27089676c56ebfaa74f189));
data[137] = Pairing.G1Point(uint256(0x1c04ecb8ad3e5275eeb1c57b22ebb5985bd5cf5ff596096e5b0a59959ff1618e), uint256(0x2e00d031e920ac8313bd089b1e7c9fb94d1fd63022fcb59576ac12889f348ccc));
data[138] = Pairing.G1Point(uint256(0x11fa06cd7e4b43b758339eee5ad7af0281717e6241d9abe14f0d426a11fb035f), uint256(0x1a46f04d490d283eba92b8a0e656ecae8eecbbc267eada8dd6167efc8f6efce2));
data[139] = Pairing.G1Point(uint256(0x01534f3707b092dff66755ea8875ede0b7e0c8852023fc6816142b7c46c8ed94), uint256(0x2f9b917eeb22da9fc29a0d45f5700f7cd5e0b0f822d7f7168c0265378c7733dc));
data[140] = Pairing.G1Point(uint256(0x25068b42dbda1d2ee147cb8d714c85ab53eb469e65211d7c53ab04dda22d9f62), uint256(0x129d4823a91d1252bbbbf9df99c90dce44492de896db24a4f5e2a69ad2144d08));
data[141] = Pairing.G1Point(uint256(0x267d252c9d9c4de5ea91dbc834f97848742bef84e430a42691bcf9544e34098f), uint256(0x250771c031f7206fdf7b4bb47ec183de97e894b75bf25bbc47d625e8d53b6b9e));
data[142] = Pairing.G1Point(uint256(0x046a16df20f49a886f39fb848c1f717106e0a962e7fbd56d1e96474eb4bf5b64), uint256(0x279ddb20850bb83653dc6114ff1dc5f3bde66432eadb99208c5c4de59064b68a));
data[143] = Pairing.G1Point(uint256(0x1540ac378aac388ccb0f80ad5336217b208e15523890003647cff02781b1db17), uint256(0x1f2d3d47af4eb1b023fa8cc6be2e8ecb55c55974e495373933bd4168b3b90bb4));
data[144] = Pairing.G1Point(uint256(0x11a80bcb219c5a6b263ac15d9e88711ec2f56ffd27d598af3ecbdb0c1a71826c), uint256(0x06edb2fb1cf789b41f3511ef00ec75c1a99c11817acba5e5da753b30869e2cfd));
data[145] = Pairing.G1Point(uint256(0x28fad843f54915624871a5c7ea1ca02ecf25695ce03b900f557954c7c5b86b0d), uint256(0x137ed9a72c17c5e56bd57c01886d8042156ea2fccf252976ed58f92d649ac3e7));
data[146] = Pairing.G1Point(uint256(0x07054c71fe3380bacae3821e0c4567f0118712544562eece3bc33d9776b2d6e1), uint256(0x1f05cd57f950f22f667d324cf0d9b75d815595201c8a6c27a73037332ee4cbf6));
data[147] = Pairing.G1Point(uint256(0x099385657ee14a77715fb93188f01138b86cf9927a3d0081f5ebe4784eda360d), uint256(0x2875660191bdf8fdcf1062322cd63c3424a9049933e35db6fd856b3dc2ab968f));
data[148] = Pairing.G1Point(uint256(0x2fd0653689e0cbe576e261a84d5a59996e7526377cec12f785e788641d288148), uint256(0x08d8080b7ae7936911144c114c78db0ba3e676580827ccf241361c63d51f62ac));
data[149] = Pairing.G1Point(uint256(0x2615179fa70ff628acfade2c0f7a5d790150c1ee95e1ffffbb6ecef5650862ad), uint256(0x0acf1663d05819bfe46d370c064a7b9d89faeb3fbd39dff842c663db41c6c15a));
data[150] = Pairing.G1Point(uint256(0x10983e54c1c19a1d8894e545aa69e4277154969e3ec8940f3e0abbbf5cc7ad4d), uint256(0x0f58b3982a1ee24fea6f43a6d521262218ffd26006d4f521a1addf75157cba39));
data[151] = Pairing.G1Point(uint256(0x26697c55dd6c7de7c39245c9963ef670a815e3508b3fa97636bf1918986c466e), uint256(0x22f0204460f998e17b216c42350a8ec2aa978f6909b8b0e3abfbba546d886b31));
data[152] = Pairing.G1Point(uint256(0x1e6780061a5f5067be89bf3bfb281b7cbc24c5878f469843c912b2b04f681b4e), uint256(0x2e4f16df091bed68beebe1e633f52526885ce6e6dd810981dab2b873a5774a6c));
data[153] = Pairing.G1Point(uint256(0x134270e604fbd6bf42a88da29ba6d0ef6c4a726ab759110060e7e2ded59a3fa6), uint256(0x0ec4486f764ede2531c46ff056bad2bc531c7caacece8b157fc17d16bbc0b5a7));
data[154] = Pairing.G1Point(uint256(0x23f86b9d3fb738a5feb1459280a522fc3479b7745d5cd190c4f74304f819b4d4), uint256(0x067a5ae33a263967c94603a26332ae259838c149af65a962e897b5b396539bb2));
data[155] = Pairing.G1Point(uint256(0x0b81138b8a4b75195abbf5ca7c22fa28bb0aaad2081a23cdbf76ae3b5d784452), uint256(0x162380528873fd571fbe67ca119b1d69fb66170d826a023d1e9a980ed9f6ba35));
data[156] = Pairing.G1Point(uint256(0x0315d1859286824f65a74d928fbbceac1cb3ccb16ec25db70acd9acf07b4f2fa), uint256(0x1e2d0b2dd0dbbe4b566a545b981f763671239f3958f5ba7ed772a6ccf8cd37f9));
data[157] = Pairing.G1Point(uint256(0x14da9c56f3fd05941c4493ed063bd10d1699a5eda24bd47e379ccf07a50a0806), uint256(0x20d7df58e7b445629470df79da62977d9fde5293111416b73a93d42f73f3fac7));
data[158] = Pairing.G1Point(uint256(0x1e4622f24ba69a87911ae0780b7c0b4b12f3163ce3382e11cadf91f690bce081), uint256(0x14770ebe407c98601614b1daa98325a9429080249843dfa3a8175f7ea62a729f));
data[159] = Pairing.G1Point(uint256(0x0773d54ae51c9e54eb9fa7f3b9be0d917dc02e11a06d00f6f7c336e34fda91a4), uint256(0x2a5d4b389a6a6c9e9e57ddae6d4175ccce6b7fc9ee1f059d990fe16ac2bd456a));
data[160] = Pairing.G1Point(uint256(0x0ee6dfff473b0b433087c505222b50d2e8e8f30598391c10cb4d94ba98f66030), uint256(0x17d000545996ba193afd178f089cea3caeb0ab0c8c339b430f62bdf6b60714dc));
data[161] = Pairing.G1Point(uint256(0x1c8d4f185179c36a1e87bf0fd92827ab34fbebf8af19c94ac914974279134b37), uint256(0x1d32c444a781c23636bf13a9c7520c6b5289c1f10f1c367b13cfb97614b86a78));
data[162] = Pairing.G1Point(uint256(0x15a367eac87fa2a05a5dd95329bc1f380c5a5716f6a6714fbb5d291a95ce6d71), uint256(0x1915c47f20bf7a45203c0394e2e113eb4500427a98241e58f1ca8299e4ed7a41));
data[163] = Pairing.G1Point(uint256(0x2fa9c950123e50ff5f94eb08b04d6fe6a4877e6382710c91aaa1bb756340be59), uint256(0x2eb4578c2a22b0835d5df1d3af6c111af1776e69866d0623f95ca1273b012620));
data[164] = Pairing.G1Point(uint256(0x01f2c159ab681aa27fa342ac483e92ca5a3ad59635efba0082355eb4fefa56e3), uint256(0x1a74eb5747e0e0bb3b2ed298da5f85475a4784cfb1c52289ff75b6f5b9294f37));
data[165] = Pairing.G1Point(uint256(0x0c84ebc0c32ba92ab26f9fe1fef8786315393bde38649656387527150fd343af), uint256(0x1f36cebf38a0f49fe9c8bf61ad80196c643c04679d7872b1c8f6642449344197));
data[166] = Pairing.G1Point(uint256(0x1558202627b2975ede5bc3e2f8d01ec340b475b71a77aae6a25b89df93360e77), uint256(0x23ee1562997aa8d357007ef612bfc296b5061795417d5146aa7cf8a208e76da3));
data[167] = Pairing.G1Point(uint256(0x1bad3183303fbab25bb0f90d23e9e6517ab2bceee182c1c35416f3e6f626d9e9), uint256(0x17869dfdd1a9b6c36079fd38028c0b56fe890b02b3c00435d11946b86ca8708f));
data[168] = Pairing.G1Point(uint256(0x158810cc5a16e19ab15265fc7136930661860723cad52147a1ddf5873ca7a21f), uint256(0x13a37eb82b6a28de397a7bee6ab7b559a49c38a6db02b90245306a5373502285));
data[169] = Pairing.G1Point(uint256(0x276cee4eeeb6209252356fe6b76aa60da8f9f8412afe0ddbf66b7a60b37cfb0c), uint256(0x11afe9521363e645bf4eb0c9b7dce94885b651146cfd5d1376930737e9694c18));
data[170] = Pairing.G1Point(uint256(0x2b2e694361afaeb5d6ea0f23ae2dfae5f7f5c34e65ab505c63e5cf8b167607ce), uint256(0x25cc881e91c66dab5a9a914af216a44abcf7fb3c762bddf901261a0c760669be));
data[171] = Pairing.G1Point(uint256(0x22f456b18214e8dd924c1bc5cfe272b794ff11da0152560b2f03f1d6e5bfa8a8), uint256(0x1935c5f6940b81ea70e72cb50da41365b8cecacad3da8f71dcbc7006bc7a29a0));
data[172] = Pairing.G1Point(uint256(0x033f4db09e6ffa3c50f4a042caf99043fe54713fe6a25f83d0ea4e1a271236c8), uint256(0x1fa8b98d75176ec4038146d129ab10cb76431baa69a9762adb23061e99fc3ce9));
data[173] = Pairing.G1Point(uint256(0x178a6ae99a060757cc1d200173567ac6a88375ebba1fa536a2b46d39cb269b58), uint256(0x29f40458010672a702ffcd5a48c12e18e98d411f56f7a58e98211c3af881c72f));
data[174] = Pairing.G1Point(uint256(0x15a3940948ce0d27811bf3013a35c0d813c958ce78c33d69bceeca7a4642a72c), uint256(0x0a3f649eea7aef2160dff615551a66262c6dd5f37c03c8687ed129fece6b675b));
data[175] = Pairing.G1Point(uint256(0x2f7595fee8c48726d282f913325a05874af8cdb0016a743f6a887a011a942dd8), uint256(0x07ab9c8c31ee832595fff345694ebfd454633da01692004e2d1b20ff4d349e72));
data[176] = Pairing.G1Point(uint256(0x074fa30afaf61a73b662c9af0a0248fcda521c82e11222c8e71a317c26465a9f), uint256(0x1f424c79d7d12d0cabda886ab63098728d9964fa7730b5408f812dfcd1b1197d));
data[177] = Pairing.G1Point(uint256(0x275a16f02afccba776e65af4a6e6f90a6b476135a7b5fe311a93cb5020fab025), uint256(0x10f45b6dd4353c3e26dc89ecd6e4e46469a3b0372212e165557c6fd67f21bbf2));
data[178] = Pairing.G1Point(uint256(0x095b18fb39563d49a215de5647255f931dcb6c09a317614ee69804e5441eeb04), uint256(0x2ad13ff0060412ece369fbd28223c45838e5e15679ee7b104d0f1a4030f6c2b0));
data[179] = Pairing.G1Point(uint256(0x2e6937c43cacc81f343258613211af6b9d2644fd6b3f2809e1ed3448a3169b28), uint256(0x0d17310e684a2881ee6e4423eb6bce90fd07a786fc72c4a7b0ae5ff75d8757f4));
data[180] = Pairing.G1Point(uint256(0x1a4455b48ec9d7d480abc9f7b384fc37f87613c75a6e9324f25ca88ffb7f254e), uint256(0x0aeb06da97594cfb0f03ff68fe1318c5b734fee5e9bdac78f146219c5fd199f0));
data[181] = Pairing.G1Point(uint256(0x117ce6cf289e578d877082fe880aa97a41be29b9a6af4f82024212cbc8dac16c), uint256(0x2cc39d82038419e95fe0d2b9e1a8c888d8084073ad4cef88d963d6a768e155f8));
data[182] = Pairing.G1Point(uint256(0x2e1a82aa06c83448c6582d1f0fcbacca06a3218ca18129f28a794f0f9911cdbb), uint256(0x0ffea1bc75fb6a7e5d7e46ca74bff14a209c3dce9692dd2f1fb9e865cb6247e2));
data[183] = Pairing.G1Point(uint256(0x248025e4eebb90e92c192f3a7dad2758b380d789f1fb6dd6d16c2d789050a113), uint256(0x29b16c182aabf8a4c50f60ae8d1f9df637cbd89a475da8e9c158a633c66dd852));
data[184] = Pairing.G1Point(uint256(0x0dbf8c6df8db98e45e56ed5ed9afe3200cffebf59c0b82c32e6505b68ee908a1), uint256(0x24b3398ba4dadcde87fe33b62fa05ef9d82a831c0d8cd64207cc4a4329763a39));
data[185] = Pairing.G1Point(uint256(0x0880e0fbd25b5b37a93e2a5d9e77adc8fe5930aad978917de1d4c527237f9567), uint256(0x298e742f53cd6fc176f6565df9db7fd1e1f23b4bdf026a23976203b97874e33a));
data[186] = Pairing.G1Point(uint256(0x16ca8afdd745fdaa43ac2a78d0b8354b3424cc267ff4a2b464f130f86a222744), uint256(0x1e85baabb3ebad4d2dd10fade84e1a4bfe37aa323131bbd016b87ca175e4684b));
data[187] = Pairing.G1Point(uint256(0x114287a5bfa7483e295f4c72e99b8de6a2d7bf984e309dfb4eb1ef7ed1ead1a3), uint256(0x0e08890cd9830ec9be38e3aa5f6a1a9c2034de957e9f928252b5576507ee2a41));
data[188] = Pairing.G1Point(uint256(0x13a3cbf7020aa0d39ac8a7a5f4dccc838017a98d90406ebc03dd51c2e03994bd), uint256(0x0d1defbf8c7a75adfdd9c97c45b548393360bf3a494490bd0f48012f858e92d8));
data[189] = Pairing.G1Point(uint256(0x21eb07d43c5001ad54f6a14e119868603cd3f8ba2a921a6a4f92016e17b4b823), uint256(0x2675c56307ec056d6cb2793dbe55655a5fd81092b9e25fb20912a0c7dd746196));
data[190] = Pairing.G1Point(uint256(0x0746e64d0b9b605b82e4493e1761d1fa3138a6ab97c447bee38cec7fb25900ed), uint256(0x25ea3700574eb38ad9f0b266dc436188bb7547d8061405541eaba6da6690499f));
data[191] = Pairing.G1Point(uint256(0x1bc0cb6731ff1e77f395203099b1876865555340b4d7491003ed726e46a63217), uint256(0x25230b3f26dd320734cd479e85ef874e7ca3a6fca4afd68a39806ea02dd2b840));
data[192] = Pairing.G1Point(uint256(0x24d64de9517e391b0803f1a01fa6b0ed3ba655e5942ec10ec1344afd7ce9c1a4), uint256(0x16b3257f4d4067c9f4e2fecd70cced5445287bdea233cb36721b6030661fb8f9));
data[193] = Pairing.G1Point(uint256(0x182f748acf3c79c027db4c3daf112d36daaa30836c4419835415178a4c98d3e4), uint256(0x23f33d162f3ca640d264f8aa0520bfe5760511d1436503fd2cc7349a6259ad09));
data[194] = Pairing.G1Point(uint256(0x1d2fb60f0a7f18757af1dac3836a3c73bf945815ceebc02b209c45528d17eaed), uint256(0x1f4639e652a8b8eb36b9dea4dd73ea779490539fcf261205e69896534d1f722d));
data[195] = Pairing.G1Point(uint256(0x2bd9899cf610199c14cdd0506d149856b35fee8d8fd1b9b86d06fc26292f149e), uint256(0x096f92910f1ebb84a673c98e3eb39a9c4eb9f118881a89f63a7e4b915a08f076));
data[196] = Pairing.G1Point(uint256(0x0588f3b3279d50815dbfa43dd31edb5d2c88974e8f50ece32ed7a8d3209e4dba), uint256(0x14b491411b31bd9e64aab80695da178ff2ee380709992289b7823e849512cd68));
data[197] = Pairing.G1Point(uint256(0x080b9f9e79ae4b5e3807fd04d7d39918ee93550db6a1c36d6a7b9f3a9059740e), uint256(0x2b719eae314522e3ce5d1b3277b8ea32e338d13c68e0675d9039dc05d6ddec0f));
data[198] = Pairing.G1Point(uint256(0x09e62bf0bb36ccb089458d732afc17e457f92a35f0a293618d4b619c6752a154), uint256(0x02c60a013c8cebd7e43dc019288ba072dedfa0043f1883240be1c24d9ce3ef40));
data[199] = Pairing.G1Point(uint256(0x242d5deeed0cc8b1fd1e4a3e0b486aac5c4ff6cad7f846ac1e19b46093b165ed), uint256(0x0709ac10fa99e02fc116896287060ee5e88ea1c827c90545ab0d70bcd0799845));
        Pairing.G1Point memory vk_x1 = Pairing.G1Point(m1, n1);
        for (uint i = 0; i < iinput.length; i++) {
            vk_x1 = Pairing.addition(vk_x1, Pairing.scalar_mul(data[i], uint(iinput[i])));
        }
        return (vk_x1.X,vk_x1.Y);
    }
}

pragma solidity ^0.6.1;

library GetVK400 {
    using Pairing for *;
    function getvk(uint m1, uint n1, uint32[] memory iinput) public view returns (uint x1, uint  y1) {
        Pairing.G1Point[] memory data = new Pairing.G1Point[](110);
        data[0] = Pairing.G1Point(uint256(0x1d8e57245cd528cb785eefcff5d63e60e17b13e55e97a695df0d65c9e389fb24), uint256(0x2a92b3cd45dfeb1dd5a56f3291598fa51377610034b33e399f4a20c43040b904));
data[1] = Pairing.G1Point(uint256(0x276077041891fb9e113873487b62f99fb7d9ca32926a37cdbfad532c8705f5c7), uint256(0x1290ede856b47999c5c335eee023e25d83c7d98712271ccaea8cef2782884dc1));
data[2] = Pairing.G1Point(uint256(0x2c0ef8354381de1839868683a7f2e41d2ad6741d0990afb10c68b7c045fd601f), uint256(0x1bfd25a310f6ad2efa6e012b00879593773437fce46301a297e5267562fee6d3));
data[3] = Pairing.G1Point(uint256(0x11291acd1f08257548ead1038e48155d1bbec7ca80ca4cd2fcfac7d83e896727), uint256(0x185674287235d858ee4db5469e2bdc6c0ea000c4b78f757eacc996949978dec0));
data[4] = Pairing.G1Point(uint256(0x0f3e0b49a59b6df85f7e701101d14b9ec8249990450aa3b2e87c4444680faf6b), uint256(0x149ead7e4e31dcc8c3deb32cbea794f03dc9ff97ebb202ce866a4a7827078b6f));
data[5] = Pairing.G1Point(uint256(0x0902ddf08280e5b8a010d50a356a3e7459d5d1e8295c9c080560bc31ad915552), uint256(0x2ffcf384006ae18cd710099c56482d245756d60703d4054bd1b2eb50b648a7ba));
data[6] = Pairing.G1Point(uint256(0x05a238b0ae89c1eced860fbcea70727e4457e976a5fe1a08ddd62a2c3dc7d537), uint256(0x2b17a9dbb07288099a96fa12e24a8ab36930d9939d783ae623b4e3b94113668c));
data[7] = Pairing.G1Point(uint256(0x15b5f0cb18cdaf253270158076d455378feedf750001cf52ff675d40fee06804), uint256(0x1c8ac119d287f1981526cc46b37f3575e4cf0e5d7798045dc20d8c9277ce3a5f));
data[8] = Pairing.G1Point(uint256(0x1143d88093071d0c2d9c6f32f52d77925bdf07067a99ea6039f34a3b11fefbc0), uint256(0x1c2a619f45386bd7956958f4fda7b3e3f47d96ac344d95330fb02c3e912d88e4));
data[9] = Pairing.G1Point(uint256(0x08044fcc5b4595434ccf6cd71848eec8d58d5dce3c767d7bcaa32d3c92d5149a), uint256(0x111e12943d90e1a220219d6b89f057dd27fb3aceb9e35896cd2c31454ff7461e));
data[10] = Pairing.G1Point(uint256(0x1f2a26304d0346465057f589f49a193ca183fc49a95404c19fbbe33ba7ddfe22), uint256(0x00f2116d3274a8ea43fbba8400b2cf073090c02eaae104254783c4541e4f5ca6));
data[11] = Pairing.G1Point(uint256(0x0534e4455592fdf659287d1e4ff3b72ae2b4a71930617cda945effeb33785d1d), uint256(0x0a78b6017bd0ebc96b2d3ae001d373f02752e792972f3d305ebfde98640cbffb));
data[12] = Pairing.G1Point(uint256(0x18e7be0c3c2d62dc7778577a5dd43fd93b9d3ee43d6ced99435070343e3ce742), uint256(0x258a8b51c0de3ef6101873d5345e7c611e2ac4e6514b05ffc102bb7c71b3ee2e));
data[13] = Pairing.G1Point(uint256(0x0f589b573372e41e26e0e9fbe964b5631e34049d05719dfda497565b79356a81), uint256(0x1bcd69393d25364f73ee7513a682f25049a069127bbcaf979ff425a0a23aa8e5));
data[14] = Pairing.G1Point(uint256(0x08d917f64a3b8ad9589245d0ba41478318cd4081bdeba31dc828616fb19aa608), uint256(0x0cb99722bea17569e84b6560c72e90f7ff55f55422327613f8741571ae55e52d));
data[15] = Pairing.G1Point(uint256(0x0efa1c5d2062eaec99af7fe1213feebfd59b117fb96c01a4cc07a32a9040b17e), uint256(0x0c83f45449a365c47acebea4be5f05c352a9c10e3de718df3b896f82c6ee5ca8));
data[16] = Pairing.G1Point(uint256(0x3008c8e5b8973930b1ec949d199f72024650305d9011126d6ced1d99340ce7b0), uint256(0x1ad8fdf230d295d5b21e89b37cc2c8a2245972e9ca1f24197a725e4f81e98448));
data[17] = Pairing.G1Point(uint256(0x22cd0fada36ddd62b4ac16fc984d9e46220551d7cfd7c952f9554ab3dfc9a47a), uint256(0x05bfbd4aa3b0e63df963417a4f03bbc26bc788aa882d6f409dafff5208d9bde5));
data[18] = Pairing.G1Point(uint256(0x1943081067239af67da5838d81972582a529337ae81557e1890f0bfc436d5046), uint256(0x243e6c08bccac233c3d19dc2dea1cd3c398883cdcf5ba0667ba951e0f5b1fd42));
data[19] = Pairing.G1Point(uint256(0x03e9d6dbd659a3cef5a05a564848e2fe8782440d0eb0c898e12317d6be92d4e9), uint256(0x1ec8229f2f42a0bf99f94e7f24b93a068b65a1f91f4350be989234958d2ad132));
data[20] = Pairing.G1Point(uint256(0x190af05c3a3ad196ad0c01761a4a6831fefaeafb80debdaf8755eb955b588aba), uint256(0x18741afdac29443037bf7e909995ff51af0f22d89d63d2c1149ab5ddb8737c46));
data[21] = Pairing.G1Point(uint256(0x0114ddb7a27338c0982dbf661c28f541b863c607330649bd4124a51eb4e90312), uint256(0x266414ee41ce71a14ec767e0afc437a84d0d4ee33ebbace55d10d99185a18aef));
data[22] = Pairing.G1Point(uint256(0x2967ef5b2eab2b95bc54a7f5779514269ce349169fbe6b7f91dea0b1f171ed0d), uint256(0x21c70dd3f79d6d510cda5cd74727bc1e69da3876e0b7214421c2fbfe20abb101));
data[23] = Pairing.G1Point(uint256(0x2627788e081089fe854c8745e5b00c616fb0fae156a2e085ec5c6bfa1edad70e), uint256(0x15405d65888306217f37aa2bab5af5221285b3b81af414035e7b254f8471dbb0));
data[24] = Pairing.G1Point(uint256(0x302c6c47b28b9d735f75bb2118afb5904db138c0c959200030ae3017e9410e4c), uint256(0x2fa50cdbee07eb03f0ca790221976e11e65839d38fa5a570d54fb366ae740238));
data[25] = Pairing.G1Point(uint256(0x1b65e82ee8cd20dc73b08f3e86ad9d10283f802b453fe4f081e916d79249b7e6), uint256(0x19bb3a5d9af5d9ac5056f7744c1362df2d8ae9bbd8134c653d393383c04846c1));
data[26] = Pairing.G1Point(uint256(0x00ea871cee840ef7ae9d8f19166505a9f4762d35c825d0596ed7fb259cc26d39), uint256(0x145bf536c6ba41bf01cc9a0a217ee651323c4fd3d81f4035cf4229fbb6a30a6f));
data[27] = Pairing.G1Point(uint256(0x1359ebb441f9a30adeef99ec8d87333707d36459841625e272edf8208bef6c17), uint256(0x2903dae37e5808aa85e9ddb37a59ebc5ddf34270a86cd1444a2bbadf18a5fe1d));
data[28] = Pairing.G1Point(uint256(0x11ec0164bc1363af8ad068dd57d1448d96cf7bed1187a4527ff2395c21a80d97), uint256(0x1769fd71b658d9eff8ee10e61200c2abe957ef457ec7778ecb7e4719109b6507));
data[29] = Pairing.G1Point(uint256(0x15de100a5111002cabc747d851e4df6171f7065d54a52a8bbd2710514abf53d4), uint256(0x240c96e9c62bb7ac9dc549d0749e91825cddb135d8f6c1883a5d2109eb3040b4));
data[30] = Pairing.G1Point(uint256(0x263cfad1a827bd4b806212b78d4bdbb84d5c359e72487fae05650144f05525e6), uint256(0x16686ae8da4b1dcb5c088d268d06df574060b39dcfb99b6edb55b0861ee50903));
data[31] = Pairing.G1Point(uint256(0x1bcc98ebf6c54fc3e132a60758f6b42856f4e445346e7236396bcba34f137d98), uint256(0x1cf017a110d7ce8b04e5a8fddf8bde14dbe26ec16e5ca3756079e2e48b9f063e));
data[32] = Pairing.G1Point(uint256(0x0cccbaef013326883930d86fd53e006326de5459a5072c58bb4fd4310e461287), uint256(0x01ff0e45b1280374b6b8a30242ff479d502ab4cc3dcefaf261c4d59dbafe0270));
data[33] = Pairing.G1Point(uint256(0x10f160cfa97615767f77643c091305b34ab63533715537c21ba266d813bd8b83), uint256(0x15b69000f223802677472833d08e858d6f7319783a3ee023e9ce7e0384059443));
data[34] = Pairing.G1Point(uint256(0x132067a6c031f72cd62e044323db97430d68c4c73eb79feb9711fa54acc2b9c0), uint256(0x1a27ca800f031ea31e66ab7af463d3798d4dd25e3a48139faada3c9fb03568b3));
data[35] = Pairing.G1Point(uint256(0x197831bce3e1b422562358af007538b184b5909c355f6ca682281b5508e6056a), uint256(0x2c9d297938749325202832daf0bc2adef98778c6e360928807c6438bfb4e4c27));
data[36] = Pairing.G1Point(uint256(0x2950abd90ae7fc3334d04da0a0dc5fab9514fab46f0e3cd6aa294e8ef0665d56), uint256(0x1f86c418126486392789041f10f44b6e06254772c1ca52c91e9d45cea195359a));
data[37] = Pairing.G1Point(uint256(0x0f5b8503d97033113a87ebd7d67403d0efbad785b258a3b03f23c40985110ee3), uint256(0x0e6623217afadd0d6724979e7fc01d5c2e2450f48a7a3e744698121550ae1b88));
data[38] = Pairing.G1Point(uint256(0x2c9a13254d0b9cf8f7a12d10781137d78b7ced72ca9cf1d76bb54030b3ca758f), uint256(0x0af26da0a97ecb908ef443e2574b38911b3fe2f49f3401e01c8e9e6cd070f0c5));
data[39] = Pairing.G1Point(uint256(0x16a038390d503c3d14def7a48923c2d049d7f7556937c9926123aaae65ffada1), uint256(0x2c96e3d809ee528bfa7637e12877c10a32c4d53836520cacbe62b6e86ca47108));
data[40] = Pairing.G1Point(uint256(0x2ee963ab6e45b8d1d70f5f05fd4623d38fb56ea01ad185b6a157ba69bde3fff7), uint256(0x13c1b40ee1ed2b2315ef12fc2e6d7e1259348ae320e0c0a5e0f3d1f62028d7a9));
data[41] = Pairing.G1Point(uint256(0x0549eef9e63006b0a2db046787957ed1a83fb73ee4b129e0241f56602b3c5f08), uint256(0x07663b4e8066112aefbc3c6c415f4d8751230b1cb360f9943773beb7cf58fc30));
data[42] = Pairing.G1Point(uint256(0x0976130a2c142c24732e20eb91939b2c6e497d17f6da2641378f2d5720106daa), uint256(0x02a18f9dd336b37c617ceccffff98da3d63d7fec6289363e5958618f6759f919));
data[43] = Pairing.G1Point(uint256(0x1fc0bd5577123045a98a02f82a00344b6d781dd377db361f1a6f9c2602f60322), uint256(0x1b97e340205eb6db881931be110f6dc2b0cb6b9ad2f9230c82962e608bed7d49));
data[44] = Pairing.G1Point(uint256(0x1f46fbaf19becd66e4ec32ca65a582851ade98d4e26c5679cdc18ba076cb8794), uint256(0x124a065e479a66f433064bbbf0f47ac8ad7bfe101ded1923fb5b86b0d1fe5d57));
data[45] = Pairing.G1Point(uint256(0x0ed1cb878f0ae98ac4d60036ff9a6fe2fa6829f7186ec4f6e87466eff1ce1c0d), uint256(0x1c8d96451aeeea12cbfaf4306fc38706abf1d8ca072e9bf055a140c6ebcefd2f));
data[46] = Pairing.G1Point(uint256(0x1d9d40667e65d6e0e6120b0b7d78a4981f11070552b466d60253e5ab05943ea1), uint256(0x14750491e69414ef5429dadddc02a3ea290a0f2f0cd25e94ac3872d7862d32c1));
data[47] = Pairing.G1Point(uint256(0x172620c92bdc18e3bef8a4502907d7707123af7bf07195c0c8d424763893b73b), uint256(0x2f85860260fad373697cd44c7d244d41df58db71edd6f27e56c0a96d9a6e8ee1));
data[48] = Pairing.G1Point(uint256(0x27e396bda2ab51fc285111e4f6eab39f99f9db8386316b062e1f29078de859e9), uint256(0x13ac4c770d964da23c67890d3d0b4d9d5739754768ece7a767e6e7ac6d1459d4));
data[49] = Pairing.G1Point(uint256(0x01488a4451f081c60191c7232b552910e86b7a1946d7dbee0834dfe6c5743d03), uint256(0x1c70cd1a5fa9b42cb490816362592a449fb951a61beb185dad43e2ac5e93cda4));
data[50] = Pairing.G1Point(uint256(0x1c20c40ace577fe1cb0ea73d81effd7a2b598cc8ad8ce8ea965595779d0c1696), uint256(0x0ad14dbde25ad8173649a60595d6ee96a9e43f178e956d973c82afdfd4827281));
data[51] = Pairing.G1Point(uint256(0x0d5194d35bbef79067efe337750513a299b4786cdc70f62895efa6e8415bae95), uint256(0x114a6ed66a8cee67607844e785f629f2b2ca97bab4483088b9fe463c02fccb05));
data[52] = Pairing.G1Point(uint256(0x0c73c59af34938972d5959f174c01aa6ac9284fd8c1a4cbb03152d793cc25121), uint256(0x2f5c6094ef28d41fd852860a844e601764854e796ca1a466d2d95f45bf2986ec));
data[53] = Pairing.G1Point(uint256(0x1c7a159951cd4a30ec5a03c03710172d9f76b821397d98fde4a1a0cb9402bfdd), uint256(0x1b4e8c750fc2660f075a87c033f177efffdb13616692bf4756f3cc0cf63321dd));
data[54] = Pairing.G1Point(uint256(0x112c99f5d133614ebab0292c5a1aca2568a81bb57399defd6b6a75672e38edc9), uint256(0x0740474613fd5e8bcdf87139f306f86db74f6b1364c7832283240a687b8d628f));
data[55] = Pairing.G1Point(uint256(0x2ef5207bfcb5dbfe5c2e5c269ab51476046a54f9ee468c62e1cd2b3714895ea2), uint256(0x2bae675d468f3d9c46a40ebfef6e6e9ed9616a9e5062758fabc6de1d6463757d));
data[56] = Pairing.G1Point(uint256(0x01ea41d0fa0afe4170a5fe4b4da30ac1a20699ce412eeca4e53bf752b19af19c), uint256(0x0e0bc40f98cea7ea206fc1ada61d782bc9fcde4d7ca171d16e7e12b2d95f7acf));
data[57] = Pairing.G1Point(uint256(0x150842187905c544f99de4a442782b8b5993fc1337c434476b9630e0e39301be), uint256(0x1d3618a165322851a265e9b88a63b900ccdb24aab2aadc1314fa6cefed47aa0c));
data[58] = Pairing.G1Point(uint256(0x18005f8d66a5a72dff31caa80e1eb344f0e7d9524e253831f0d21b3db97575d0), uint256(0x09a92781186a46844350eb00f9e2946922493bed3478e32282d755f1f9bb18d4));
data[59] = Pairing.G1Point(uint256(0x118d5fdd6930fa22dd0b0c8fad11e64cd01fe14b3accfaa4332d7b4a3bba9e27), uint256(0x2bd71c20dec7c522faa0232c8a48c68bd56e1bae0ae28ab1089f6f976a7081b7));
data[60] = Pairing.G1Point(uint256(0x2b059fcea0cc9cdbe683803cd0e5a9da7870ab9a35bb512adf57dab9990d3d83), uint256(0x24a06d0ccc178974daa34fdf4980caf28a9822d563ae5ec3b21eea003ec21af9));
data[61] = Pairing.G1Point(uint256(0x0a544162933d5837978cfee4a5887281d03bc97d4e55056ad659dfa8d6217bb0), uint256(0x29d1fbb9ae41e8eb6e920cdf0dd2e711a767d8f6a432903f12818e66adaac4e2));
data[62] = Pairing.G1Point(uint256(0x106b220e84c9137e8b60704519c34ef1b6edf1c8280929630dea64a387169491), uint256(0x1cdf90eca627a7935cd18759d4d40ad83b78ac0abec0f7e9df6180fd8ec8e158));
data[63] = Pairing.G1Point(uint256(0x00c2fffc83c8e6d011e79e6eb598179315bf66056ab4fc0e8bc76329beeadf4e), uint256(0x2273f91e7beece10bd6f8f25874bef1b0192248984de9f4307084235261b14ae));
data[64] = Pairing.G1Point(uint256(0x1ee5b9960045b34d6a906d8435b5961faa224068b476e5a176f4a4f550d15681), uint256(0x12ceaeaf9b495be7d9f39250496245d0ff0e7981376642e593ed41b415740aa8));
data[65] = Pairing.G1Point(uint256(0x20edd9f62fe449be50ddff1dd0adea406f2a64a0b5f06ff326ead6be5cca6b90), uint256(0x001e6869115244d0d94f6c12b82747749fa356f17cd8ce845fe7332fbaefc5f5));
data[66] = Pairing.G1Point(uint256(0x1823caeddfd1df21376e609ea98a28f89ddea2cba3a0dbaf89fd452250195dfa), uint256(0x0e0b9865a1f0dd53fb0078743cdfcd42b64414e60038ad031e09c90c68b1a0d3));
data[67] = Pairing.G1Point(uint256(0x29ec3f92564bdf38a6715a16d085fd1117467788ec77473b7338fdd151e559d7), uint256(0x04d9b629aef3ad53879251b8004ac720fcdbd10579a7dabb406d56e96a3a00c0));
data[68] = Pairing.G1Point(uint256(0x156a6e65c3797ebdced55524bee5b1c4a9d6f3b8fc26ec3cbd2bb8a09086cdc7), uint256(0x26087345596e252ab6a57b1309aba87e6fda0ed2024fee3accd9511e0bb67a9b));
data[69] = Pairing.G1Point(uint256(0x01ac00121cecde6507da42e72b0aecd9bbc284504530e58236275bc2cdc0d9b6), uint256(0x09bbd78465c6721e1227e3ac3799095f06e1944b1b0f3701aca5c4575424e5b0));
data[70] = Pairing.G1Point(uint256(0x181ab5c00e2887b1b83d5f58619541dfbedac2682b8dd99acdabc9c947b60fd7), uint256(0x21ddd8a2f61de8dd1975eb1930eedfe86f0e7f10f3fe8b3edc25c6e3c3b353b7));
data[71] = Pairing.G1Point(uint256(0x1e9858504c8713b35ecd94d0ee68ab2e161546c018822500df5d13d32ae2cbea), uint256(0x1afbe4dd0f9a52a4ad7b1f0eaf7f4a78a3156041c4b258a28a8f1f5df3c96aba));
data[72] = Pairing.G1Point(uint256(0x0d5eae4701935c1e1720ed862c309d3b4081c6ae1f8e80515e8de388e78469a6), uint256(0x28f736467235778759b165a9189b9da6f0a672f21d7fbebc5c844d46c4fcf2a4));
data[73] = Pairing.G1Point(uint256(0x1b9536b0313e55da2f55b79ed09812369e1ea43ea814a989d7ee5c5d672c8903), uint256(0x300f7a47586566c3fb7b37d7e11bd6a31ac90d44fefd912debbc64e30a86da74));
data[74] = Pairing.G1Point(uint256(0x09ff0ab6c11a5566fdfd799a57029df86569f26e4dbdf9aa52f32d62931f6851), uint256(0x0e5765ec86f923da57f1a231594213e5306ae9d6273ad1a2692b3fa0bcb6d22f));
data[75] = Pairing.G1Point(uint256(0x0ea8a92a4e43883aacd8a8903f19741565d7598307420c31775ed00d78c8ef31), uint256(0x0c6012e456616cca1471d66b3a97d9f6d3991688edc680da6ecb155b9491b9b4));
data[76] = Pairing.G1Point(uint256(0x0c29314ad2580f336793bbdde7a82aecc847e6fc7ad0093b90ffcf66cd91fe9d), uint256(0x1691ac0861560c3be18b601f9059e2b273aa63911dca3f3ba90d451b51dc3323));
data[77] = Pairing.G1Point(uint256(0x138bb4b7dafe59c96af444ce1dc6c776cf6684914e59bf9848fd527dd450c876), uint256(0x294a1022977c7209f58bbdcb1081a18cc6f890f6a4b639f93ee07df4009892f1));
data[78] = Pairing.G1Point(uint256(0x280a8bb3c33810af46b17cd375b9e7368d8aafeffce60c22069ca8746c10cf88), uint256(0x077c714a4218cfdcfdea8bc4638dbcf3088fcdf003a680688257499d52662d9f));
data[79] = Pairing.G1Point(uint256(0x1133e6db6bdc103bc5d442ac9590d607eccd841e512772fe0548337ab899d267), uint256(0x1320e11d6beb4b8f99a06040984548eb2b995abd5cd2b84f873f6a7f8e36fe28));
data[80] = Pairing.G1Point(uint256(0x17c82254756174c54abd8874d128d30e4c85caabd223ce92c80f258ef15e783c), uint256(0x08907b76d20998b8a7929ae6b40bcaf836e63714a45cd52fcbc82d74d468db21));
data[81] = Pairing.G1Point(uint256(0x1806bd204bedb8b52e6dc4cd4da5d37b04c36138e53384e32761a0e0ae583f2e), uint256(0x0167b0151ffa8eb101a8108ef26df4aa98e84d870677f8686cf4adc998469c31));
data[82] = Pairing.G1Point(uint256(0x215d062c508321881a94b92906bf2e3c8533bae80bf58d16fbd66582c1cc4249), uint256(0x127cb064cb5d6f6552b7d70be94eeb211bdcdb1e3a797fff4c68ecf0c2b135ee));
data[83] = Pairing.G1Point(uint256(0x085366f25add3387aaea9557e55cd32f95e4a7a03752660a892f0c6c7afb37ed), uint256(0x18d7f8c46ffdd31e7cb23da16d17ffa474a06d21542d2da7a689b19430651b5a));
data[84] = Pairing.G1Point(uint256(0x1c4accd938cb8ab492c1eabd1627d37fa34a6d9314f56549d21fc596dbb3f08e), uint256(0x1ba30b06cafccf69209b535a76750e45eb7906170b03817d367f6e199f8b5801));
data[85] = Pairing.G1Point(uint256(0x2f19dea495bf2ed0300b2c628b381234efa9dbb3bfcda795fb53c83ea1a491e8), uint256(0x1868dab26532816e0b264f116e8ce9a398b1cea602e851d81b24fa564494f34c));
data[86] = Pairing.G1Point(uint256(0x20dad809d7ad736269317ec12009844041623e997851211d4cae0efaa8cf57ba), uint256(0x244bb74880e7f5cef08cc90e04fa521eaa669cb519559463e82baacbcc2fdf7a));
data[87] = Pairing.G1Point(uint256(0x1d459d44b00b3f1d0437634f1f69fe29ddf039ec0b5688b25f84d4c22f8997b5), uint256(0x0913eda2b4413198af020f499371835eeca55142873cbcd72452a014929369f7));
data[88] = Pairing.G1Point(uint256(0x044fb09b5bde18039d534ce3ac97b025cda57abd185516a40aef1582bab7eeeb), uint256(0x1560595eb7f987c53bc99c7899814d365f35fcf1bed9401cc11e2369b22771ae));
data[89] = Pairing.G1Point(uint256(0x26a47f29aa0395bd9446df5c0fe88b136d5009e1bce1a011ac219b34a7a3ccfe), uint256(0x21cc2d1c150dbb7997416f32e96ee8c5185df249d6fed61b8402892a8d210a38));
data[90] = Pairing.G1Point(uint256(0x1dd9fc721cb7b8fc68d908c080120ac087058568992d0289de44cf6d8cdf5719), uint256(0x1821ee3315ec25bc8551ac1e8e6daf9c0c45cfd77e5c27e4350e9099ddf62cd3));
data[91] = Pairing.G1Point(uint256(0x02f53fc2e028a18e8b9028fa1042d91b9ff57f78b879fc787f4f32ed4fb18feb), uint256(0x12f6158da1d6e9dac7408fab3e31ffb3b7325bddb12c32c5a2b7430e085eac8d));
data[92] = Pairing.G1Point(uint256(0x01c6e0a8b04219b787146ac5051c7f59b4aa73f8bf897c3403e942eaefbf548e), uint256(0x2b63e899e985d43adbade5f8c1c163b54c80beddf928f192ac37c64f9a93246e));
data[93] = Pairing.G1Point(uint256(0x14a7215eaf3763060c45c0b3b22e056efda8915cd3e7be45eef05274585717fa), uint256(0x14a21ceb202e09f8efcc002155a5bc5e3934a2ee7568186f0c318c076635ceb7));
data[94] = Pairing.G1Point(uint256(0x0e3150d013083430aea4b06b1f3faa7492ec0d7f3c1e5d0138505ee360f87403), uint256(0x1b8b2b7b94522639a4eb79eaaa17c92bce85371fd900cf5cebf7ca7b8f753956));
data[95] = Pairing.G1Point(uint256(0x04bbb194d6500a0aeaac442859571f49bf54fa398b1d2a41ce8bf9370cc8b289), uint256(0x07645cff5040ed749d7483d474e50346b1f9a1420ea2393a69dac85913d53aae));
data[96] = Pairing.G1Point(uint256(0x098ba7cfe1b74f5a44f0a59ed76819670f14b5f3a5bc868d70aec0a1ba6cfcb7), uint256(0x16fd82346c87eb7437919360a848e3a0a6ea1c16a6cf291b41829baa1f00117f));
data[97] = Pairing.G1Point(uint256(0x102bc960bbf8bf6c8236f6879da47dbba73a0adb633f0dc8786bbc4dd778b334), uint256(0x0680a58298242cfde7d30061545600b620bb4ac7960cbd9b396e9bb3f550fa42));
data[98] = Pairing.G1Point(uint256(0x0b30a01536babe1f92cefcb084654bab18deed7b4d1ed63e14d08e761aff8420), uint256(0x01a040f523abffc86aaf1c92453ce60319e997486d13ba32f8a10439ffd231df));
data[99] = Pairing.G1Point(uint256(0x2fc568fb6b8d72fb2f4e7bd998a80ded15be147ecbf4b0f81e0f4379f858cacd), uint256(0x2431b781f39a083bb48eb9742af51d02e98996a2a15922124dd93384989b7ac4));
data[100] = Pairing.G1Point(uint256(0x1f923a3dae5604e157a73ac10aceca26a1c76475788f77e4e84a2fbd9370ea57), uint256(0x21b2be246ec1657615be7e874117d7289978e2edaf0e8576b4e6fc4f078eff2a));
data[101] = Pairing.G1Point(uint256(0x1969eb6c956951c3cbf3501d3b2c827c8aeed7228ac42a307be01359ab623d9e), uint256(0x2a8d235edfc50ef22bf472550946702be383d511e2309a4f4edb8ede2b2fbb8f));
data[102] = Pairing.G1Point(uint256(0x036f4ab812e70124061f13fcfdab8e0f59f371a1788c840aa59ae78029fb0625), uint256(0x1aa5d702886ef1b2bf16b2d4c09fbfb08924a4978875bea1b0f3a0b3d037cc35));
data[103] = Pairing.G1Point(uint256(0x1c74722b5fe6c8df8cdd0d44b17c932022f4caea739cbe6dd4289898f02dbfd7), uint256(0x0bc9e1d039411ef01d1a738a753d6d6a6ab767e53c648d94ebae8e1584bb570c));
data[104] = Pairing.G1Point(uint256(0x1ecc74aee9593c46d8a5bb4d0fbf07e6bb16c6ad611ec45e774cfcef6ab4246a), uint256(0x20845ebcf39c5aab6b9fa24ab2897e95defe7eee14e48b14849ba6448acf5515));
data[105] = Pairing.G1Point(uint256(0x2689c37dd0c4c283b30ca862a52a1c1a4b8a58faf1d3c3000041bc6265bcc9cc), uint256(0x10306258fa49865f9050afdbc8ba2740ebf3a30bb43820b467fa973b43186e2f));
data[106] = Pairing.G1Point(uint256(0x0663f3614561f46c5c6f5a2d4958f16cb1081293eb829b118549c282b26ffdf4), uint256(0x094f9d65e30cb4f082c18aa160c749eeaf342b69288ec28307f9de09eb4ee9b0));
data[107] = Pairing.G1Point(uint256(0x047d98b4880dd5c813cb80c2bf69a73e7e855b507d6fdaa38d0f8a27615c4d36), uint256(0x24c7c793ec45ea704c2139baf5b145a39a14c7676ae4d2aadeda0910c2f6b4cb));
data[108] = Pairing.G1Point(uint256(0x27ee49dc4eac79a11f9f95294d6b30447a70bd5bb6fd8516cf78ce97ea4e016c), uint256(0x1b5c9717d1df9f6bb1f2eb690fbe6f4764aa5a7f2b17890699686b7f8b10999a));
data[109] = Pairing.G1Point(uint256(0x1b0fe263ba0af553d85e1b6f83f9bf5c9418c4fae4b227d60bcf0b368b6602a6), uint256(0x05f4d221d465b846e2b2db7cc779b3bf298753627aa035a52280ece0167957cf));
        Pairing.G1Point memory vk_x1 = Pairing.G1Point(m1, n1);
        for (uint i = 0; i < iinput.length; i++) {
            vk_x1 = Pairing.addition(vk_x1, Pairing.scalar_mul(data[i], uint(iinput[i])));
        }
        return (vk_x1.X,vk_x1.Y);
    }
}




contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point gamma_abc0;
    }
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function verifyingKey() view internal returns (VerifyingKey memory vk) {
       vk.alpha = Pairing.G1Point(uint256(0x0454a398d50fc0e3820934d246ed516a2b41700112710b0fef7ab00d317d6502), uint256(0x24725bc9b7449a345d6cd6eebc423b3ad3a44807e9c84f1fff73d9a2a2112b63));
vk.beta = Pairing.G2Point([uint256(0x2a37f0f3b046212539787ba9012cb78c146d002af44565b68e72ab7a82669f0c), uint256(0x17ce9bc4f51b8bed6b1c5f70d6075b5007e09ca962d0ee788839fb6c9b3fbf0b)], [uint256(0x2536c502e47338d04326b812ad10ce0b2bf78c8c0e890b2803a509f6621c3739), uint256(0x1307d59a0bbd7a9f9065743a56ad8ecaf62796e1275a29e42548e08a19083711)]);
vk.gamma = Pairing.G2Point([uint256(0x13b86d251af4838af07d4b6e56f39e8f5ea5fcf9b33c2de96ee355ff58b9ca49), uint256(0x0fbecd981ade33eca93e9c7adf276a824da5f3ed53fb1277476c7bee6c57bca3)], [uint256(0x069a6e2d143e375b9ca8019fa7a22042fdafa1df066a7490255baf39e4e9533d), uint256(0x09803898ed37102e9f0f63c32120147fe96fb68018e67dc0843b572a944b74b3)]);
vk.delta = Pairing.G2Point([uint256(0x2c9639cee78e0d6c9fd94d817576d49d51a3e21d89176f628ac0f8d88b834327), uint256(0x111e122c34e44586a1e0a4d55d73db282893d4b12e891dadaf682ed5bfe13790)], [uint256(0x124807dbf96d5780d7247370449dd78fe030ec9b67e5779925b0987f3f6c899f), uint256(0x043916fbbf2b9cab392c58aa7e0cd8c6296ccaebedbe052dd0c6159484160876)]);
vk.gamma_abc0 = Pairing.G1Point(uint256(0x19f1798a65a799b1c7c43d554e7e1b6f842132a0723a15a0edc6aae7d4de1e74), uint256(0x157830a7c782515212d5cac834fa6f0aba63f36b5e9ce8ff58a551114f10fea6));
    }
    
    function verify(uint32[] memory input1,uint32[] memory input2, Proof memory proof) internal view returns (uint) {
        //uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        uint x;
        uint y;
        (x, y) = GetVK200.getvk(vk_x.X, vk_x.Y,input1);
        vk_x = Pairing.G1Point(uint256(x), uint256(y));
	    (x, y) = GetVK400.getvk(vk_x.X, vk_x.Y,input2);
        vk_x = Pairing.G1Point(uint256(x), uint256(y));
        vk_x = Pairing.addition(vk_x, vk.gamma_abc0);
        if(!Pairing.pairingProd4(
             proof.a, proof.b,
             Pairing.negate(vk_x), vk.gamma,
             Pairing.negate(proof.c), vk.delta,
             Pairing.negate(vk.alpha), vk.beta)) return 1;
        return 0;
    }
    function verifyTx(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c, uint32[310] memory input
        ) public returns (bool r) {
        Proof memory proof;
        proof.a = Pairing.G1Point(a[0], a[1]);
        proof.b = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.c = Pairing.G1Point(c[0], c[1]);
        uint32[] memory inputValues1 = new uint32[](200);
	uint32[] memory inputValues2 = new uint32[](110);
      
        for(uint i = 0; i < 200; i++){
            inputValues1[i] = input[i];
        }
	for(uint i = 0; i < 110; i++){
            inputValues2[i] = input[i+200];
        }
        
        if (verify(inputValues1,inputValues2,proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}

