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
        data[0] = Pairing.G1Point(uint256(0x079b5726bd16b3ce35a730f6a46cdd5720a7ba19c9cb0fae3b6ad732fdd4fff9), uint256(0x2ff7fa9934c92753231c1dc185a4f6a7232f7a098e7e8dd9c5207bf9f8c2a43f));
data[1] = Pairing.G1Point(uint256(0x28fa82c831976aa3200201fd94d13cdeaa5d92f6725db2ab24da7df24d069c4c), uint256(0x1c4deb3b6b4864050e0229ce2e570f1c2bf132a0fde24840c0dada8f87efcbca));
data[2] = Pairing.G1Point(uint256(0x10e5ebfb9c6e6c15120bf86cac3fde8d3888bb929d70bdd95d8b72128ea62345), uint256(0x2ead68ded4d4e27057cd96a9b228a7e39b7bdc5a46522d9697aa83165ea23a87));
data[3] = Pairing.G1Point(uint256(0x1bee659039ef8d1376398c818574b08c1dfc269d9bce31b2ca5253161d777d2e), uint256(0x203c965a65e844760d269a25c2857fd4bc2865e04ba795368ec49633f6c4ab0e));
data[4] = Pairing.G1Point(uint256(0x07569c036eba38f4fd1467202ebb9a7a5e0e32b4ab493885af3986af74056720), uint256(0x20b8f40e752142f1d151af5b0cd1f191a6e380137da2bd5b675f2170da8a9aa5));
data[5] = Pairing.G1Point(uint256(0x2247db6ce09c54c54d7691d410d3bc3b42fd8176331b62e883adf73621bede2c), uint256(0x10592380925977a93c7447175580c057f4599dba0ae77aae26d156b27341724e));
data[6] = Pairing.G1Point(uint256(0x0522a4deb6b5ac318e9715ade81ea0910becef4adefc4838bf73a98d0a5d288d), uint256(0x2e328171e611165d55deb1a49dc92c58ba8e1a63725a8598612f3ab24a73af7c));
data[7] = Pairing.G1Point(uint256(0x1e49eae713188f9154fe3f7fccd205aff0c7f372990085e00eafc6bb79df92c9), uint256(0x29a94aca11c1bf9d200a1091058185390d4c8fc2df690df4cd02b7f7564e5d04));
data[8] = Pairing.G1Point(uint256(0x21217c7644087a868d0fef94d13dec903d2f104ade33fd896fe446ce71a45412), uint256(0x12cf0e38bc546c8c4ebbfb84477b1bd26ccf3ab8e509b1803b981c07f4fa9df3));
data[9] = Pairing.G1Point(uint256(0x2fb223825825d9014ddfa4dabbf461dd5357d6c64df662f90f176807d4861f75), uint256(0x1bd8c65c712e5f87fea33fce093466173f84e180a9bde99c29e66688ca3e4df9));
data[10] = Pairing.G1Point(uint256(0x15192346a21024d0fccd039d1a253a3fcff24713b6a62c7fbd55d48911501261), uint256(0x152a495970ad1934c706551736b132a42c3303d5408c3263dc6d7405564b4538));
data[11] = Pairing.G1Point(uint256(0x17c420bd5b65f05f96b22b816d669ffe3895bd4da397f14466081f50cc40f2c0), uint256(0x0469e5b40bf2dfd616076ff76bd327666c333778913c650f3d1d5f2e7dd494e8));
data[12] = Pairing.G1Point(uint256(0x1a3889d3272ace35f1b0068349d313a4ef9313412704fefbaed33cddee68197e), uint256(0x1b1e4cb4b4793b43e099bb234aeb282365a91b998629f7fef2b887ce35209703));
data[13] = Pairing.G1Point(uint256(0x1a4ec33c56b046946364c089ef7394d942b301922b4be3d26aede5c53f39fbf5), uint256(0x177faef013d4a831e7a06f7df1c8ec1b261b5bada59f3da9f22da9c7416b1c89));
data[14] = Pairing.G1Point(uint256(0x17365a90cff959c830aabb32d6c657a37fc0be7893e90c1303a89da622d449c1), uint256(0x14f29aa53353163f7a29eac8eb922a1b5efd3b3a4d25c2cb56fac248f6449077));
data[15] = Pairing.G1Point(uint256(0x2aa0eba029c7b2133eddb20788841e6a85b0f91338b1674a9a9750b3acfea0b4), uint256(0x0c098e2afe62cb60a46cb42b9947deabaa744e159c8ec4426c501e9be44a804b));
data[16] = Pairing.G1Point(uint256(0x1e45ceeedce60ec24a09002b1328772c30d41ce37702c681ba2e85624540b36a), uint256(0x2a797e2ba624ac6478bb70653a3d8cd373a6702278c769bf92c0361fffa2da15));
data[17] = Pairing.G1Point(uint256(0x0658ff111cb69f4015d0ee55d1ec3438ef7aa8498f9db3e5a064bdcf857ec078), uint256(0x22669c08d5cc0bd72e238da87553a9f401d29cde37ce61d8585d3d1057e24a14));
data[18] = Pairing.G1Point(uint256(0x26da36c4fad6ce06d39ffae30c73c6871ff58320e3191cf0e76f91ee3af9c280), uint256(0x28843b71cbdbc46c78540dc3250042fd8918d92b802adc0b422df44d38611431));
data[19] = Pairing.G1Point(uint256(0x20a927dce01c3a48b60d4a7bb0b6c93c5fd12b968bfc8666d6501718c787b356), uint256(0x1967c6c432f0df39549a0822c6d4ab89cc943900ce547953312f1c0c43f4cc86));
data[20] = Pairing.G1Point(uint256(0x0bf2ae88ddcc0d79e74d7f6fbade7f9b45e8026202a062e6a7433397949a3c06), uint256(0x2249591b4136d8239d93cfb6cca050dfea71a37a22e9591f5bd9e74446c0e212));
data[21] = Pairing.G1Point(uint256(0x083e136ac792b86f282fa407a145e0ae6a856d7c1a9ee526c866cb2df150ffff), uint256(0x22d0bda91c531ee93cac355dabfaa5a3c861267b2ca962c5d362c62ec74b4d7e));
data[22] = Pairing.G1Point(uint256(0x14ec38364fae02ba913e5dc50863dd455955aeb5ea629f4b2a69c1ed96ed3ae3), uint256(0x25dfcbb0a1bcca6e42da5228ef2488ad127e6c93875d8ffb91e5c52e97b54c18));
data[23] = Pairing.G1Point(uint256(0x214a931fbac36ba87f6d2ccf43dabb34f3b0e5159cbbe10b699e3633b5f2b5e5), uint256(0x294eeebae7da9afb6ab5745b414dd633133404532e44c42c3137eec92ee40d8a));
data[24] = Pairing.G1Point(uint256(0x2138bd36a00ed2f8b4fb4805450689c4ee3cf8bf02d4899b2a266075f529ae09), uint256(0x04b2289aefee7f2016b3e2e2fc035b3721df3542dd116b91d63ff060d11dba21));
data[25] = Pairing.G1Point(uint256(0x1c3f0c220995ab6fade43076b69b88d8c8e45319a74362f048983289adeb7e78), uint256(0x145c5bd00e651d368bebb2e1947e5d1911e08673d86e1e586dae0d6d5d91166a));
data[26] = Pairing.G1Point(uint256(0x19d90779e69d4a58b59facbb9aa8d9115dd73d53326b360c8349459e1bf0e0e8), uint256(0x1e775ebe38032bca6f86b50816351ce2bddbb1bf040154653adade8c0a65e3b0));
data[27] = Pairing.G1Point(uint256(0x2db92556b07cb0d45758270e4d747ba960d1e69f95c21a53c682a48a139146bf), uint256(0x0a8346faf699fd59baf55b7425aa4a47b9daacdfd9e85375ed10f47c74ed67af));
data[28] = Pairing.G1Point(uint256(0x094d5251d8efaa9b16c54b068b83a34c7101309614df8f1606ce4cfbe29cb29b), uint256(0x0a116380accd6595a51af4dc83a71f1ad1a3bd8184f4ed55f18e1b5e2289d314));
data[29] = Pairing.G1Point(uint256(0x2dbaecb79ae862020f9b04d2707bb9a28f1a0c6ad5b4d33adb17bd8f8d6474c6), uint256(0x0214a585885622b299f75ebabcccba55a3d71acabe84f4b68589451245eb1d3a));
data[30] = Pairing.G1Point(uint256(0x14b71634249d235c31a326609828113007738bc92f5b9f4106546338e4fec016), uint256(0x116d0db19296e17ba8ae31796001f59c7c4184bd71801a5ac0c2531de58753b3));
data[31] = Pairing.G1Point(uint256(0x0e55ea059776ad7febcf2b108657e76d7f98395f01704402c5977ad31caf6860), uint256(0x150da49524093895f24574d5c13f832bd43ad29479249c9277a55b833a9d0fe7));
data[32] = Pairing.G1Point(uint256(0x1b0be14f88f3ff775a874c25014fec7f767448460546d7aa3bccb19b301a8195), uint256(0x00e95d0f415504bf7ece9abaf7de75e01f75e1c021ac18fa5da3b21e4b96903f));
data[33] = Pairing.G1Point(uint256(0x0018173387c02a5fd9eeb4ced7b97c03b7704e08faebe7abfaca2b0f49cd50e6), uint256(0x2b827d60c04b2712e09794af0726d730acbe5d99bb8c06fed689dc2a8b37eac4));
data[34] = Pairing.G1Point(uint256(0x1bcd9ba6b86d792e68c056b8f544d26989312a9cf4fc78b5c8ba78e3d5ff0919), uint256(0x2b29f1c66d11c09ea7af4536ecfb4aef477d049b37f9610095f4ec1e05d93429));
data[35] = Pairing.G1Point(uint256(0x18a5f3da00bba3d4a0022f0e01206032cb6570b0d73af66e1ef596ea8235831e), uint256(0x1f907670c9daaea3daf525c3d3b28099ae979d3507120744ba2148745272b40b));
data[36] = Pairing.G1Point(uint256(0x24da317236d29e6d6b625044e711fc11d13526c4fb410650d056bf5f53d3de74), uint256(0x05883617b08fa71327c63c562b07b380548ecfb775d317e768a7a1d75337fb92));
data[37] = Pairing.G1Point(uint256(0x2478c02656a9c3ea508cd6d6cdd5dc19ae94b80ace87aba923e97c8e16c6d892), uint256(0x29ee58f6dc54f4707503d08d94eae92fee2df19a7236971f22313737cc874694));
data[38] = Pairing.G1Point(uint256(0x0a0881de9ee5d50685dc1f379735ca26cb9a8a553da5e875252900e50b230eb1), uint256(0x0a0cc7964eeb0a48d4bfa69f85ee27b02343eec5d6f5ab8376117edd2f73b6ad));
data[39] = Pairing.G1Point(uint256(0x3054a71aeb6cd55161a42ca8ea68c4b1f69502acfa193ece0f4eff07bc2cb0c7), uint256(0x18d2607c2d8b8f417fac04087ed85be6ede4b17e35e5e1eafaa8ccb6cabb2c19));
data[40] = Pairing.G1Point(uint256(0x19b6ddc7188a14ac7c054dad58158998ef77b55650ddd75f030aa04c529e4e23), uint256(0x2149dc50f1f9cec76ad5e14fb9573b09158eba7f0f2069a921af050344565716));
data[41] = Pairing.G1Point(uint256(0x19f6039828f85bb5ef79ec3605445937dd3f186a6881407f65da48d705c1b1b6), uint256(0x0259eb7389616f4de75bb7996c166760f7128e0efc428e7cbab345ef6ab7e6df));
data[42] = Pairing.G1Point(uint256(0x18fdfe808ec9e19a29da75b9dbf99c8f5a11856cb0c5b626298e4b610c8bea53), uint256(0x124f180488e8e0249c5fe8866200fb88d1b29ac2f5911a52eec00b268319f65c));
data[43] = Pairing.G1Point(uint256(0x1ce9dbc42108ec48edccf1dbd189fbc360df810591426783567e3a063bcbbde7), uint256(0x16f48a3b85165734756ccc212e51c03961f46a26bce4fc350389838c911c17f8));
data[44] = Pairing.G1Point(uint256(0x2029acb718139883c83a9ab4c8ceaa626e34e852be8c2daddbf04d39d0d87816), uint256(0x0460b66dcde97e03a4e1d739da04ca67fc1e48ae61a4f7ea7897193000c904b0));
data[45] = Pairing.G1Point(uint256(0x04dd3726f643acf8368c8b9e1be88e4bf02b6e3e21401a2af30ff1db5f68c9b3), uint256(0x1a6fc1cac4cff854a5b636ef300e5dea902ec4dfbba4046f111a8ee1191d8fa0));
data[46] = Pairing.G1Point(uint256(0x1ddd26b0430a4452e225c2d506a0e8c3308d488ec49386c03e47dd213f31f056), uint256(0x2e537184d34383583fa1d5fc43d976586cfc00f8e7b4fb711c7f001e74c2daff));
data[47] = Pairing.G1Point(uint256(0x128800d79424747b730874aeb523850ae6caf6eba6fa7c2c95adf0dbf5c52d3c), uint256(0x0e8fc80b482077e2b1c280e6fd9401da5c57bc79483ed84c6f23723986e0deb7));
data[48] = Pairing.G1Point(uint256(0x27c2a72baf2badb22958176bf1f920e1c759da05ba028c6a4f6539b262c4fdd8), uint256(0x0cda58e44381f2610062bc29e3927e8ebc02351f960e3fb7ff6badb7bdd180eb));
data[49] = Pairing.G1Point(uint256(0x13f9fc5d593fb035658dee5fe38c1881b10f291478cdffe122326d116dba6836), uint256(0x24870826490d5daef402c54549ff44c380ef90f8f977f62b7b97efb7db609503));
data[50] = Pairing.G1Point(uint256(0x0e289cb25343ad11922596fa5abe71efec735f374b90d60f991fd812b6ee5e00), uint256(0x1a59dcb375f6a2072900aa4398e19c346fbdcf8eddefff4f17adbd18a2a249a7));
data[51] = Pairing.G1Point(uint256(0x17a7c2a70ab13cdee88147009f5d33efc7a136c912b6feec327071b17adfccc0), uint256(0x0ac892b3607e3c402a0762e63741fe508427f65e91d3a95ab121a42b4de6b4d7));
data[52] = Pairing.G1Point(uint256(0x2995759a66f99c593f09e6de50b489470a6f2f8355faf0f7f7e95d32479d10c5), uint256(0x116d53ae65f377709bd928b628f3ea7b0b56510eccc56dd6b2dbe52eb6d53808));
data[53] = Pairing.G1Point(uint256(0x11e5538923586795ae70a2d24cf0555a36a07e7c552ea5bb16ad304da7889679), uint256(0x21356a38e567c4f02887edb9b7f3e441bd3405f3176e2b44a322bc36f237b187));
data[54] = Pairing.G1Point(uint256(0x25d33ef09b11c8b944687e053748593760474d5a8d71f1a715b7fb7d1cb2405d), uint256(0x23c872e810ccfd4a614ee7cd987c8133482397d77d1bd8e6b5e9957ad91d7721));
data[55] = Pairing.G1Point(uint256(0x0ff7fb346f765ab112eda47bd93bfdb2b5ee00ea481235271ff56f845c1ea39a), uint256(0x08fc5cd6adbb9ed9b903f32ae85b0c223dfc9291cb0df11a36a3327d0f436625));
data[56] = Pairing.G1Point(uint256(0x17a86fdc62bb43bc4dd8589a5b66e6a835b26d11d4d9f4cc638a29c0147c6b48), uint256(0x1b5e375532b20a3c5c19ae83dfc62674747be7dc328eb3d19a6d2f86051aaacf));
data[57] = Pairing.G1Point(uint256(0x1b638b7a0331f75248297752a98e440024eec587db262fa294d9a8633ecd217c), uint256(0x231d6620029ea4b463f7908e0ba66a3150ba36ea1880e519df0e1c1e3fa79624));
data[58] = Pairing.G1Point(uint256(0x109ae09890aeaa89e7b1e8ce4db53bef745bf981000e9314370316051ddad882), uint256(0x0bdee8ee3ba3628b847349832e8d092fb19bb944f3e4e06c72f420c00f51a6ca));
data[59] = Pairing.G1Point(uint256(0x0fbdeca40bdde0de093740c200b5d2057519394a810d95f902c2ff80efce99d1), uint256(0x2bdb27d94f9e8a5c61d91b1ad290c858cf1fdc639b8f6a3834ae1af1e1f5a240));
data[60] = Pairing.G1Point(uint256(0x154cbc1feb6a1dbabf28ff185f0c5d429cc8043ed035146f129c194f9513488c), uint256(0x03bd4f1d37b6e662239ecb5bf4d28fc30493fdc27217db9e44e1850918eefb43));
data[61] = Pairing.G1Point(uint256(0x27dbd3f35a02ee165dcbd21333c39b7f6c8a8baffe0557e4937fbdc3bcd171c5), uint256(0x2aa51bcc128c1a950f9a2af9648a3f141ed975df1d9e86d8e9829eccb3c0ec55));
data[62] = Pairing.G1Point(uint256(0x1ebbe822f9218e42aa9898ed5093c33c76f538a50710375c3fe832863316da86), uint256(0x05c149d299bb500b1e98f5c3b5d5035ed1c3c890b1a0e725423f95a1ada9879e));
data[63] = Pairing.G1Point(uint256(0x1d5a1a793065c7d419854e09099e8d5917a26e3f0c7c6806132e4273265add68), uint256(0x1e4e70c14e1276bee49374cd3723d67cb71d52179b2fb6ed5d45a2c7cb24cb9c));
data[64] = Pairing.G1Point(uint256(0x09b86801f062f14771e1445e6207adcc7ad3dba629bf0b6a58a7a786446785dd), uint256(0x1737ab0ba0f9c24fdfaee736f9d8ee36ff786c6e3dd92d52a536396abb1c56ec));
data[65] = Pairing.G1Point(uint256(0x1df02752f3d46d784b13eff8f089b42bf6281a5105b7a4b74d756db5f5740a91), uint256(0x00f00bb6a75db445585dcda7e306cd076d49542eb0293c711325056b9152a5ca));
data[66] = Pairing.G1Point(uint256(0x12eaa3102692026ae0b56d82c27116778198d9859feb7a45ace4f29dbf774fbd), uint256(0x13242f9cff61586db3a7355e0a210b1e590845f047855eb72972cb72d1c6c983));
data[67] = Pairing.G1Point(uint256(0x02a07990531263e90426c2d84276c276b665e69e10628371ff53d0b3ec828d22), uint256(0x1bb72b9cc9e2809cd46f7a2808cc96d55a21317bc27c38036599bf7b69e331e9));
data[68] = Pairing.G1Point(uint256(0x0e926959085b6495bc82b86f02e8f9f62e8b2cf483952b1450b55595a7df55ae), uint256(0x269653e5db20311b8701a1cf27e72ae69f26d37889d08c58cab7ba55238de6a7));
data[69] = Pairing.G1Point(uint256(0x06a90b4e912acd39245a7c24ea45fded29199c8ba5e53f67d9486b51ad1e672b), uint256(0x213f3078564e1c9f7ea8e0e47be474592e14afc41aee9f467638e7837789759b));
data[70] = Pairing.G1Point(uint256(0x024e860c76eb896fa4f95519752e37c8124edb0c96be588b9c277ea1bc314f9f), uint256(0x08d8a473258be498b210785c84b0cc13fe396484e48506690db5a5148cb29504));
data[71] = Pairing.G1Point(uint256(0x2bf8f62fbd585e05270fc69b7ba10e383d7d4d47baec7246200a1ef9b96f6c71), uint256(0x24b542184fb7e00bfa418a8303116747926208716c2c32c5337fea040a0ab8df));
data[72] = Pairing.G1Point(uint256(0x269119a079b4952027b376b197db3929c460cee61113f256655e05b5357a8f73), uint256(0x0eb4a3c5dc36d2cd23950b77453d4aa372d5c1bb50b9dddc57c02280527ed700));
data[73] = Pairing.G1Point(uint256(0x2b98b370436ade8e28f96219b5fa6954d92e72b0476e9ad529d889715b70a6f1), uint256(0x159c2c066f6ec8bc7f5a957613c4d215302be86c7d8ee897913c50d5047f0ca4));
data[74] = Pairing.G1Point(uint256(0x122b7df881ea83a3e9c23c66fe3850dec287b4f903b49431138ce951706fa0c4), uint256(0x1c75aa0f41cf3aa8850cb00343db3b889a0e82756988c2c61ee22b0630fc5fe8));
data[75] = Pairing.G1Point(uint256(0x033844c47c5eb8a272dff73c6af7e1ab7367ab5d32e49b9782be8f0baa41783c), uint256(0x29a5b91591913f703f68f20a11881392e6b501721d794f8446ceb056451f1896));
data[76] = Pairing.G1Point(uint256(0x2e7c2b49fb46e2df9e7dd16d97e46673dfd12d668134dfae3c74c0fe4c180666), uint256(0x2dd8124022c5f46cbaa5fb26dc212d37278fcf1496831fe0e5de05d60a96980b));
data[77] = Pairing.G1Point(uint256(0x284fccc53f90148306c4cc02ea9f702cc7e80905ae3cbf50662058eb2d01c1b9), uint256(0x1bdb61f3eb7c6dd371a50689aca84fcc3bf179dec8ecd218c47e0cb812d0aa1d));
data[78] = Pairing.G1Point(uint256(0x0951498a092a93ca86b22a7864ea1acc745a376da2af1b9f7e6acd1280ffa47f), uint256(0x06f14ba35851f1e52ed2297d96498b21401561a01f95644444a8a20b8d746c36));
data[79] = Pairing.G1Point(uint256(0x140802853561e55c4d8be4058b690fb47d602e31fa18c3958a85da42fc57e42c), uint256(0x28ca43bfabdab8ccd75622b480f2881cb7ff124b68931758ba5bf484217b613c));
data[80] = Pairing.G1Point(uint256(0x171e88eb87d19a484d597d15c41e6391804e16b3a0126200df6ec74fbf638e88), uint256(0x006b11fcfef470a91dfb467ddc1bb46c60b4f95330460e09990d5c74316e5bf5));
data[81] = Pairing.G1Point(uint256(0x129182e7ac5e63db63eac5fdc76d4ec13a4ffaec6c87ed78ae49f9635aae2404), uint256(0x29ea6b79d81d69a47ba18e58036586900c440e7c50fc69a2d531993a93171947));
data[82] = Pairing.G1Point(uint256(0x04ec615953179f1be3420e5eefca682ab2ab8752fd5cbf52e6a5a262c7e81982), uint256(0x254435095b0df0acd1daeae72fd99b7ab739c2d157510656f7e87b165c4006dd));
data[83] = Pairing.G1Point(uint256(0x014781c9b736c4d0bd0a568d844c22e5abe41f6604aad60931983e7b3ff88079), uint256(0x1101a265d7c55cc404e875360e39d08ea4d056448800ca1b484c13aa982d225a));
data[84] = Pairing.G1Point(uint256(0x300f2bc8c94a44d9d9fbe6bbfa8a9a53c32e9744da3078ce0553783439704898), uint256(0x0d36d6dab5ce375640e1f20e881d67aaa7d5aeb21d897f8f9b0fa76932faf545));
data[85] = Pairing.G1Point(uint256(0x1b3c1793580e4a30b6c6d34756c153c3656c70d39efc97b2a15a43cadf7d927b), uint256(0x2d44cabc0fce1db83dcde2f639606cadbdab8d471b7644d23aada8ca62fff85b));
data[86] = Pairing.G1Point(uint256(0x24baf623c6177cd5e0696a856d9f0c39c26531d1ce1c9a6c276a9e8a2764d03d), uint256(0x071a547e5b919988cb3af9b68fa8eea24d5b9b063617095b71d8615113cb441d));
data[87] = Pairing.G1Point(uint256(0x025d0ab1b69b5645300b50d0a0373e7cfa083c657eecf6f5c38d01132a4d6ea3), uint256(0x27f29f7e771e2abfba86e0845888e8bea7995ee98bb456776344e41c6e6c12e3));
data[88] = Pairing.G1Point(uint256(0x163c0b34c2f9580141cde68088baffda3ab7c8ef7ac499a22c925ba88d3eaf29), uint256(0x0b2330d4e528093cb003bff24235bb65b2a073304867b7be58d2353f8b3b7726));
data[89] = Pairing.G1Point(uint256(0x19c7aadcf97d0c832d4ec21863a72b641b33380fdb25fbe0bacdd8daafddd7b5), uint256(0x2b5c85c79e3864c6b3653d7c1bf575f4c609bcb6cd5d5604367770535621053e));
data[90] = Pairing.G1Point(uint256(0x17e6ccfbb85ea9baa29e5d1d3e5768012adc70bfa3fb0fed14907fa6385b4a8c), uint256(0x2ebe97c28efd7a53dce772c99f93f6a52fd91ed3a2871708655a73b19ab195d2));
data[91] = Pairing.G1Point(uint256(0x1c9d73fd6263f4f3b2ab301d27623c36bda2b7cbb866c49e0bb2af7ceed40043), uint256(0x18dbc7a0376cda045780270efb8409dd956f41435d7d78539fc000a77d3b65b0));
data[92] = Pairing.G1Point(uint256(0x21dc52342d86be6914c52bbf0d7e8da1a242bd6923ca53803462a02874592702), uint256(0x1755c3604bffbe974070f83b5e8627f6e07c91e1d26507e42b7f82dc40ebdd8c));
data[93] = Pairing.G1Point(uint256(0x0fdb5f103dfa1c849c67b8898768b598acea15d0567652b85a980a38fd2ed1a1), uint256(0x06217169b319a888ef390a8c4bef518c3b25bea84b6e63e86c988d82bd680393));
data[94] = Pairing.G1Point(uint256(0x16a7d348d41f023cc751151aa35fc27b44f852f11adc907a19c44b0a8663607d), uint256(0x0afda2719ba2aee8250916bea66cc5ade34d54d94070b32eb0f62b1ee40be5e8));
data[95] = Pairing.G1Point(uint256(0x0973f90b908e8556c3db0d1e59b86ae0aa2bb3f5cc40c8f0e2d9c706a347fc88), uint256(0x252b0f8b4bd25b23359ce0408145f9c587ced44df258a0cfecac6fdc9631532d));
data[96] = Pairing.G1Point(uint256(0x2176dcdaca1264f3da59a5bcaa78125513ed57c8bcd76b3019353299db356330), uint256(0x0e514c9acf1f1a4793c5d5c0f0eea69dcd1f9cb7efe2926c26559a4ae0314f68));
data[97] = Pairing.G1Point(uint256(0x1a4e767148f1b9bbbf51f030f67c95b4587c9f936a8e28e614bc346e2751f81f), uint256(0x26ce0b083d9f15de0117f7eea800ddb3d18f341351f0f5492115ae753163cb59));
data[98] = Pairing.G1Point(uint256(0x18c539a022ae28b5107737421915f28d427d256a44300def3a8cdaba2b7a0444), uint256(0x03b9f937589978159dd62a71ee8587621a0680161e3b27e2ab6361b751101aa7));
data[99] = Pairing.G1Point(uint256(0x19b5ff0b4668e6ab4af876002c0664c4bba2f38bd9d1794cc161e29b0d7668fe), uint256(0x1875dc85b0b36b25d8564339298d75b06a15fdf1106691b3eddf5c6433974799));
data[100] = Pairing.G1Point(uint256(0x054cfc40f61a58639a3a2a9745dc3d91bab85c51575d960be9d6f79ce6b5df1a), uint256(0x1ce0fd8679393814fc5f2851bac3852a7243c97d00b93656f1375727fb88a12d));
data[101] = Pairing.G1Point(uint256(0x28986d9aab435d4cb249254c4d67e67b4eccb4a56a7e7214bd8d03027ec16bf2), uint256(0x10de88cfeb972006bbd715adfd1afa9833b7ff75a3d9e3a085a00129f7868a52));
data[102] = Pairing.G1Point(uint256(0x18c0ce5a088dd38af16c6bdce27aaaf369db937c069cce56975960e1f6c4a9a1), uint256(0x2e6d5c21001c0e271dc45b4a5fb7b099be830b2b00e126a89268f95c5c218dfd));
data[103] = Pairing.G1Point(uint256(0x172f374dd615bf86cf748d72cefba07925132c7f246718741c0761dab6e39ba7), uint256(0x059a147b0b63cd11532bc1837383ce5d814633795c53e56f1e1058002c47a607));
data[104] = Pairing.G1Point(uint256(0x286b5c22667146297bd18f24cd70d55d25f90117105a82eadac088e76eacfa60), uint256(0x18fb8d0347946eba6c3b798a8bf2e795fe2ffa6dcfdfe5715a99f4f38af8adb9));
data[105] = Pairing.G1Point(uint256(0x0078c34e595ecf43f66dfdd713dfd0af27248fe043ebce5fba44d86cc18b751e), uint256(0x21edcf848e316ce8ad4f02b7c726fdbd6ec98e6df0d16b3f40b2cd2f4ce03865));
data[106] = Pairing.G1Point(uint256(0x27d7272af095068a1057303b3dca6fbd693cb76787de1bc4f7824b2f69fa3b6e), uint256(0x08f1fae4409fdaf95255ef4b92583c84061b52744fef85898254c4b2aa87a044));
data[107] = Pairing.G1Point(uint256(0x09086f5c7ca5041504ed9d33ff671b06e702aa745f3f03862409a8678066b4af), uint256(0x2005a523d36c690c21972b9dcbb1f1c873efce8e3d097bea62fb9fb5458ebe18));
data[108] = Pairing.G1Point(uint256(0x0ef14c078dce67bf5b32676d342ba87ea325ca6730c7e3d4489ad4d65d36927b), uint256(0x266c4d802cb168eeee6bd4c7e0a0c8bbc83741507a251225594e438f902f8c01));
data[109] = Pairing.G1Point(uint256(0x196072dbd05c20cbd7a8b8865999662c0431b6c8a913aa9e96f0bd144ca5ca58), uint256(0x1b35d5d6b46255a11437cce233674e683f8cfdde63a63828c529d03e5ae86f8d));
data[110] = Pairing.G1Point(uint256(0x0a3428b18ea8f72a41ca86a41ef9967ef37281176e4f45aafa269b5818a35c13), uint256(0x07ed167f6fd73dd3ece246ef4b267d27f5a6f21d8db0254ddc4ca94d6fd8ecd7));
data[111] = Pairing.G1Point(uint256(0x12a3c52b7d2643a4bccb0f5b69e54d234b54273d7f5093c196df8c52b5812489), uint256(0x23b6e70416fa2674dd85612b3ade2906bb47b9331c61c7538d69896aa899a1a7));
data[112] = Pairing.G1Point(uint256(0x1d752751fcc75042fced0726e8f7690b0759aa7cb5f013fea851d498bfb2bbf6), uint256(0x1d4cf65e7af40bdf27f9adea9bea98e5157f40b1f437107918e064e3d5a8fd9d));
data[113] = Pairing.G1Point(uint256(0x220946775a0611a612ab808888d123e6955d008d42bc9c8644bc2e9bd94d2590), uint256(0x0928bbfa5686cf362cdbf9d40a863c368bdfd9f8f9185910123e6d5ccb6f719a));
data[114] = Pairing.G1Point(uint256(0x1d80a923b8ee63d2778ba75c1207c4de2dd4618b347852a702ad89b97fe3d0fb), uint256(0x0b790dcf85850fe534c44df7dd2664196f1f636bb76b3f721faaefba46df7c72));
data[115] = Pairing.G1Point(uint256(0x20942a1d56480e140764d6b044f97c791cfcf9dcf49c19177ebea22afcae741e), uint256(0x0c8f79f3a7cec00b837e9f633bb434a50f50e090e5ad810101d70e9c452cbfb2));
data[116] = Pairing.G1Point(uint256(0x2617243fe9777c7a6a6877eb13bf2363b9263ef2b5a4fd3b2c8194e6b1b7a96c), uint256(0x1b2b002215b7b6f11a36a85b54a00fb1d4e301f1fbfeb17724b60d5a5c7d2482));
data[117] = Pairing.G1Point(uint256(0x06b23e3e71fb4dbc35e617ef9825d4f2cbb910b51ede53392c6ea67f104fcf72), uint256(0x01d5e2e8d36d463ce09577616fdc83ae59092b90615ec896ff1a14ecf8c528ce));
data[118] = Pairing.G1Point(uint256(0x2223806134c579e5c5f35b07f7cda6a6dfdc99a5ac3ec751f827766473b91f15), uint256(0x1b1d5d4cec2752be3385cbe2159e5b5b050dfd77cedf7c8e1b3f6bd683229507));
data[119] = Pairing.G1Point(uint256(0x125fec63ed0f5ed934465fab129dea62fe8a7f3ef802be4fdf024e532f40680d), uint256(0x1b541f10db20481a8deb380c9e48d48083c5fe4030f426a3eeb6ff568fbf99e9));
data[120] = Pairing.G1Point(uint256(0x10c8d17b8dd449071b511a6038c3450d6d79b4c4196f81d5c874f373010c9cf1), uint256(0x0ba53db4c8088c3b6749123720f56823e82c5ae3614c4fe478056e343a3921c2));
data[121] = Pairing.G1Point(uint256(0x1dbcefe1f9d73232e00ee5fdb59ef8304ffe2389ab092d0954eb0dde0e383268), uint256(0x07d3d93abeb38c9173c57d240a5c1c3c153c1b62d415ae2ba6b895a0c7693562));
data[122] = Pairing.G1Point(uint256(0x1ff63138fd0f4d03c70a735f4603e7902c1e78617a56e5ce8fffa67bd14ab375), uint256(0x29a3f72cfb0f619f22fa9498022abb090b4efbe38da233268eebdd6cc81213db));
data[123] = Pairing.G1Point(uint256(0x27f6396431298a51daa840e72ac6c85f0868929636bf94d136c6249fde67a560), uint256(0x22e9b12afc84c0f3e8162e0b90b026d3072a1c86134616f9f8106020dfd82122));
data[124] = Pairing.G1Point(uint256(0x019948211973acb38b90eb4985ab74a4d29d10a4130de06344eb007fb3378fb7), uint256(0x034f60f6552b15e264e15b7573705039787a31e79b499a9926640288772d22ef));
data[125] = Pairing.G1Point(uint256(0x12a090c34828c065c3ceb98e5ab44da64eb445b05bb05d44a8c1f88a84761123), uint256(0x19862b292bc94d4d9e72492ff711aac160709d3ee55940f6110d4c600701e3f5));
data[126] = Pairing.G1Point(uint256(0x2aa9fa96c850cbc6c7c6dab87a9e8451f66d3a154654ea43c075016474a193ec), uint256(0x0c44d42a9e9b5ac9d543ba1e3fefcb411a32c00e94ad73c60e3bfe7b1ec6c6c2));
data[127] = Pairing.G1Point(uint256(0x0b85afde58e7a0e14b0ed98243a89b17d7f38731c89c79781c8791dcbc9c6873), uint256(0x0e047a7905dbf6347a1382f9b32ff692a63b8da2c98d919806207adbfbc5b29c));
data[128] = Pairing.G1Point(uint256(0x1519309f2383e503d451fc72d5e03708baa486547778b00a20ffa523fa4fb49c), uint256(0x10eedabb4424e187c05f8e6651f176aae2c1d06b77cb4be8b5120f80adef2dc2));
data[129] = Pairing.G1Point(uint256(0x13daac96545f65caa07fae878f96834c85b1bf6857c03892efb986155c8e7396), uint256(0x077e4242bde951c7aa217de25ad0ad7f79ed2bca8f8c75dbd9d8e971439d9fe5));
data[130] = Pairing.G1Point(uint256(0x233da8ddbcdd66e292f1342fcbe6fd39bc641552b1f9b82b9fe077cf18d80a94), uint256(0x11d354be8af6988e022f65275f29e8caf956642294e443de733314acf55ca729));
data[131] = Pairing.G1Point(uint256(0x2808d983eda0d172dc5f223c16d31970da8f5e759e548aca394ed02b7cc509de), uint256(0x131c77e71d1a77cbc5991dbe0340502e7c9b698e35dde9f09806773d9880a9e9));
data[132] = Pairing.G1Point(uint256(0x1e40d75010a024b19c7b6078969b2d5954bfa5257f5d853a3ee4004437ff990b), uint256(0x0df3b8fdea1e3b75afd184cf5e36c9a97e7ec7ec53360857cd497a204344b416));
data[133] = Pairing.G1Point(uint256(0x08d631b7b7576c16e80e038596207e076c1c5ef19d79e20bb8c0dff33e4fa839), uint256(0x0252d4563fa18c924998a40a3084f54e295411608d2ff5d2939ec486b68929de));
data[134] = Pairing.G1Point(uint256(0x10155b0115a85e97aa8c156744851efae258dbbe9d012d482d5c9b202c40d19a), uint256(0x1e883d638a4ab119820dca75aeb84ad9aa27f3e63fecbe57d24d4c4b33283509));
data[135] = Pairing.G1Point(uint256(0x252f2dd4fef55fd08a0f60aff2956053f0c731795c22a43f72a1a6d032014cdd), uint256(0x21329ab678eba216a3eb1cb5a68a31fe7e50137361249dea3f5785a10091835d));
data[136] = Pairing.G1Point(uint256(0x1d3c7fa551b2c556f0eb3c73b3188076210fdfb702a98f284121941060d25055), uint256(0x0c653cd963a2626ee3c5c10049c6a18759ff1c4cf697eb8373a86488371b572c));
data[137] = Pairing.G1Point(uint256(0x00187f202f03b6fd28911cc4d419d2e6e6334ecd461cb80cd6f235f6bead11c0), uint256(0x004a9ceb973dcb6ffb73d352e0b9d476116a108cb97c492a1df995bb8d4427de));
data[138] = Pairing.G1Point(uint256(0x21c0904aa65a84fd4f29667bc173df534b9595916e8b901677254dee975c22fb), uint256(0x0ebcfab3e17c1829256459aaf005f1420e144ffbcbeaed99778ae469a6d1da71));
data[139] = Pairing.G1Point(uint256(0x27ca39c50194cc7fb382f07ffe00c227a3cc791625d201f3cd00795c8fe06aaa), uint256(0x107cc025255cbb97de1bdcd82f619f440f87a009eb5d8673d5f321de4436c6f1));
data[140] = Pairing.G1Point(uint256(0x11f3da77ad3c02e091084db8bf2b1df094803bc7cc7599e72a607965b935980a), uint256(0x2c810240e0d1bf7756e09ddddade86902f0ed2c3ddcf7a0cea3f9dec6af756c6));
data[141] = Pairing.G1Point(uint256(0x05beaf2c42104c503ffbe8e8442ad5717f76da4864617ef7004fe8ccb68d39f8), uint256(0x04a26544a039a054ad286d6580ec1354d8ee27c3e11370e8865911447eda2cff));
data[142] = Pairing.G1Point(uint256(0x126e5ba9f77b9686f76a7cb6c7170caf8fe22408e39ba11d180e603da7e628be), uint256(0x0c747f2f855b4450bf94221a50f357cac61a37f502b8d9d218525570fdd8037a));
data[143] = Pairing.G1Point(uint256(0x2106214280fe434acad60b273533aa53e378f7682510d142a8d1412c072d3dc8), uint256(0x196bae574c7d8fdb2dd37dbbbde2f260962030e2e5d14bfcd7ba7c759361f1f5));
data[144] = Pairing.G1Point(uint256(0x1830579794ca67d88165c4d2fb43130f1e18fbc20df98e3d749cd57642e43416), uint256(0x2cdc505dbce9a8fd7aee6d07bb7aede61c4eec5d96666408e6f018390750fcad));
data[145] = Pairing.G1Point(uint256(0x0d20ccbf05dc613c1ddc740a6e9491a2ae5cbd5d4d15bb7b3efef58f24a776ff), uint256(0x02156150d0c57eab47ac51ac5252ce9464fb2df7a79702dcfbd9a18093b8ee9f));
data[146] = Pairing.G1Point(uint256(0x189b553691f4e64968d8971ea56ef53adfb8ae1bd7dcd9e4ffbd2cc2d070d408), uint256(0x20b038391e5fbdd589aac2c1852ff4a1e32f7c5c1643dafa4f789cc79b854472));
data[147] = Pairing.G1Point(uint256(0x2c6817a97a9a237aa3b3d4bca8ac64a3b6d791d217f859fd029c67413d3f0c78), uint256(0x1d1f9e0af6d2a76e814aa1a8ae0c0668cd0eed5db8b6c015380c42d1587e14a9));
data[148] = Pairing.G1Point(uint256(0x1ec7eff3dd7d2c6d96db1a5f7eb4c719aa83234c7f89c4a5b0d39929e6ff5eeb), uint256(0x1bdb2434c08800d415ff3d84562de48c7407b4490d222cd63b6819ef5aee4e5b));
data[149] = Pairing.G1Point(uint256(0x112a8259040fae9e697b1cf82902295357a1c53f0fff5e7aefbfb8dab96da59c), uint256(0x181fc01750c32fcdb585654647678eca2ee79780dbd1266c36287979238302a6));
data[150] = Pairing.G1Point(uint256(0x117c9fa9bba9d6295c4e5f1b3e4f70d91f90ad375b7180986a9d00ad8f3e9ab4), uint256(0x10cd029ec6e400fa426eaea9d6c1b7695bb4625540b082a8cc04f0d28b11e5d5));
data[151] = Pairing.G1Point(uint256(0x0b387e11a1aba4438f9a7c19085fad2b87ce47d004f2df3d345b80fd83ebdb1c), uint256(0x11fc60d5301dcfcc82f95b42d6a1a3c53f9133175d62a23fa91c93958ea78b9f));
data[152] = Pairing.G1Point(uint256(0x003ff69e41f16360712cbed5a31dc945258d6f83b0d93e159a6a4d8ef97f0d18), uint256(0x17ef152e68988794e451c46c099c01feace27830fa5cb4899728509a7e67a8e4));
data[153] = Pairing.G1Point(uint256(0x11b711e8ab4fa21ea5dbb54df965f0f49699808f2fe0c6d73666fda2ef1e7bbb), uint256(0x038db3356c3bd04240819b94718df714103a9305845593840f96ac26f1d3ede1));
data[154] = Pairing.G1Point(uint256(0x1b83fb1d18b237d99027fb993dc8df53f9c450ef7d355378964584a3fe1cb8d5), uint256(0x1200fb5555d01918d13126efd09a260bce345d55264872f76d071c550ff2835c));
data[155] = Pairing.G1Point(uint256(0x12e4da5bc8ea2e0a8b78fbd977bb57a4c9fe55423cb2a0c1d58fd1d1f2192788), uint256(0x227b70727af3208a69a55c3a65c465c939754e8b4ac77062dd5c57e84c2e5362));
data[156] = Pairing.G1Point(uint256(0x195787c13b2f657d9acdc999856f186743a7762819f8d4558a8b7f027c68680c), uint256(0x03dd8a69d5c5121b0bbbd5aa12032c9eb02548932d36c39569424a43a1a99e0f));
data[157] = Pairing.G1Point(uint256(0x0b672cae66b5036388e1fa1d001bc91ad1aadf60943f0e592ad29c3b3f61e7a2), uint256(0x0b9eb9cae690dd431a5579858fbf685123190782ebe16a9c31665a96b6b26bf0));
data[158] = Pairing.G1Point(uint256(0x28b88236482f0cb2ab9d22e44794eca4a5423593187b00220759d4c1ea1d54ef), uint256(0x00e0b01d4d4786e76b50fda25193500d62c7fe4dbc205425ff27132c95fb3452));
data[159] = Pairing.G1Point(uint256(0x0b6322f93d2f14b393edd643052c8dbbd0d3a484090cef16d001829b42ea1331), uint256(0x19b4f72f2ac8c22e1f9b701fe58620ece67e82e142f19c4c0cf07754473f6a84));
data[160] = Pairing.G1Point(uint256(0x2e315ed6cf2d558468fe5ae43d721331839f6554fb612096946a0d274ef67ce7), uint256(0x2bca5c73db7793ba0fe0a7e9e31c7638ce8a2b427836019c6dee91d7667c0cf7));
data[161] = Pairing.G1Point(uint256(0x1b377e6ed9b54e57ca080470bd6c7ab66feeb2679f2dd6e1dea11c87c20dbbdb), uint256(0x1481c2a2387621390f75dcbe4a4e5f897c91200af71ed56b0cedf249a7cf175d));
data[162] = Pairing.G1Point(uint256(0x1ebd6b22c91636f5c3620e72306c42247c431d2476730e514b8414fa4c5efe00), uint256(0x2d8c48685e660895464d32df6dfb3740fa686862099ae83ad13c378bf61e735f));
data[163] = Pairing.G1Point(uint256(0x1bd9b5ee6a175565127b666adebe584abfb46db582cf83bf0cf72c0525be3e90), uint256(0x26b975e37450e94a89566c50b594fc284d57ef4b22908cf05a70fd24b6f59e8c));
data[164] = Pairing.G1Point(uint256(0x0b97b976a9cd29d5991e04165728652064181598aac5a456b664499a1d9578c5), uint256(0x20402c659021f5cc91ea1fd39d4db6daee5da3cabaa1f4b13b3c3b471ac7c50e));
data[165] = Pairing.G1Point(uint256(0x24d82caa033d026a2f41da261cd8cf3565ac67fb96a7fc796d7d33364932a330), uint256(0x02cb6ce64decc2a289e14a1d074159b78d5f2d89b8ddfffb2198e06c4fc031a7));
data[166] = Pairing.G1Point(uint256(0x1c7f5c78ad1eaf9670b6ae1afe7dd5dd007be52267d93e5e4798074e8e6984f2), uint256(0x2412db320ea65be991e779f184db8ab950c44895eadca8acf9470f02f5ba56b5));
data[167] = Pairing.G1Point(uint256(0x0d5ccfdbff107a7b3441d7e4d4226eaacbfd79ca721070a7a0099a144900ad6c), uint256(0x290823c7cf076298e4bb67d2bfac9d31a526599b6b8274cd2e6991abf45df90b));
data[168] = Pairing.G1Point(uint256(0x24357e92f32967b43560befda1ec38c6a7fc9b4927fe0882da933519e29b5e5c), uint256(0x2d7d6c4a47ef7be80f9a7546b5b217ac54869ac76facc2fb80267811af229109));
data[169] = Pairing.G1Point(uint256(0x06adbfdb9199586f9971b31b9884506d7693da767556b1ac50687a9873dc78a4), uint256(0x1e5729e65302754f6b637bd6cacaa69986704b67a759e2cbd12f8684dcb894a2));
data[170] = Pairing.G1Point(uint256(0x22ae388d054ec851fd091f57ced6e5b2b14d3558416d969840fe5846b97f57c7), uint256(0x16c19c2bf656ef898e0a9ecde7ef2f4b2cf66b74f787596c849a36711543bb25));
data[171] = Pairing.G1Point(uint256(0x142701440ad537b416c10be0a7a230149a090fe173084f685095fbd0d5bbb2c4), uint256(0x0d676ece643af1bd2914df5904ef091132abf0ac9d8936c990c5a9d57453ecda));
data[172] = Pairing.G1Point(uint256(0x21c0fa31458c61fa5a861e48d0b474cb79df2ae32b1d25eb3511580a93ca3cc7), uint256(0x0df76f053fd14b345b4cdfbc3b66dbbff6d611351e2eccdcbad3de99de38d088));
data[173] = Pairing.G1Point(uint256(0x2f823371f48f226bfaa89fb41ba1a6ea194878e5a6084b4da1ad58d3770aefd5), uint256(0x2fe1b573b4e774b83f47d2fee073fcea7a1b5e22e1fe76f5a2717909e64debab));
data[174] = Pairing.G1Point(uint256(0x22377f0a477fe50323de78dac5c1954844941052d434ec57f6e9ec144278e68a), uint256(0x28ed8cbeed718c84600ee8b8b65ce562e7cc9d80c6822124b953f86ee24344b0));
data[175] = Pairing.G1Point(uint256(0x1d0171939fa2125ccfe9874537969914821ac736062b2da94f37dcddc1b570cb), uint256(0x1570733093450ab0b824f7959c578e71a524de468b7d161b2f918db25a1d474f));
data[176] = Pairing.G1Point(uint256(0x0021063a6d2453d4f19e1c0fd082e0fd47d79b061429b13702bf3bae7617ac88), uint256(0x2261019779451b752971f50790e635ef94b90f81a27d0f0f8115aa54774e1be8));
data[177] = Pairing.G1Point(uint256(0x0d494fb38a7cb74167cd58720bfeb9845533159ec8d4979ded3131264f70192f), uint256(0x0e6f3254b6e008b4c7cf6ed77b8a763da3ff8277308164d17ab4f80a37afcaaf));
data[178] = Pairing.G1Point(uint256(0x04017bfaa0b0a5d3c09028d8f4ee951feafd1dbc62a9822f1bb69bc10c3eba1e), uint256(0x1c7535c67a790a7b0a0544512dc8079ac30835bf0cc9fb724bd39fe9e8244afc));
data[179] = Pairing.G1Point(uint256(0x1e83cf99bf8f1dd6294cb509696be7bab16f9c09bc6fcab92c973b442763e0c6), uint256(0x1e40d79da0170043c77893b827cd3074356121110e6ea1de66247349cb18bb57));
data[180] = Pairing.G1Point(uint256(0x0ce16103c11a8de164bf533f08ce4468375a42195f43b71237d1259030432e55), uint256(0x124919119b7c82801be88cadedfb895c64303a84330d6ae5fe86cef508a6ae96));
data[181] = Pairing.G1Point(uint256(0x300bf32f8a97fb7da53cd18364bec8a9bf1480f38151fd902d7568313488147a), uint256(0x2385abd09ecf9b316de8070c63a75518e4584642f090f6cfc3b04257206e4111));
data[182] = Pairing.G1Point(uint256(0x0857840abbf483355a5c557ff93f64fca37f0fc4a6f3e92cb3205b698abd8896), uint256(0x0b456a70f7c60bcbf4ab6ed44ae662467738f56b4ed0ed427218aa3dfe8e21e0));
data[183] = Pairing.G1Point(uint256(0x2b235678f86affa8c22689ac6f45f258a77e1c198216007be37c64043c0504e4), uint256(0x1e43a453688633ce612b65d5263c83ab73712f326cee6a432468691eb5f5226e));
data[184] = Pairing.G1Point(uint256(0x07e1f3b0ed6a4db6d4c475d62a78a5b7046f0ff9e8e7387c6b318c4bcb754701), uint256(0x1b6f2c2766e046eed53257df9333194c12a431eeb86abdb9cba74def43f226ce));
data[185] = Pairing.G1Point(uint256(0x2e49e16cb396d0e696a0cc046f419e384359e92ca7197f83bf347ab633130db4), uint256(0x24fc474958d01d07035c58488ed4810c7daddc508d2d833c8590f72ac58f1939));
data[186] = Pairing.G1Point(uint256(0x0ffe7c72f550f420dfe3f19eef0948eb32300935a0cbe69808977f89214cdac1), uint256(0x0c54b83dcc2a086cae69a2a10cd23606bc8bb0acd5b48079761b579124734e3e));
data[187] = Pairing.G1Point(uint256(0x07593d0b6caf6e1c02486294b1eec6c46ff65dd157bac15e7f39fbd70ad5e7fd), uint256(0x14951343dc8cf1be0bc0b2c384d69f0b93671b30428a6d090ba4ee7c4784e41f));
data[188] = Pairing.G1Point(uint256(0x0345f34445a279d7de2edf5e865260964aca1d73f3064a1934fdba49793d0dfa), uint256(0x161c25de1b8f15792f24a45bd5c073fe9319ad288579533a9aeec9e8915a5bf8));
data[189] = Pairing.G1Point(uint256(0x2ba6b716238445db0bbcc81565fd977227c93f31c2062dc336996503b3b04d86), uint256(0x08cb5c88ebb7dcdfe86d04455470a1831ed9dd26af02fd79b9f92112fca6ba31));
data[190] = Pairing.G1Point(uint256(0x2340d003c85d2eef758bd42abd69865568ebb49f37de98c0d385acf385ab0de8), uint256(0x2f9d95065da900859e199e0571953f3ab9942fe2015b498900add5e1e0589570));
data[191] = Pairing.G1Point(uint256(0x14f542ae94c54c276ae985aa6185d3f31ace3e4eb5aaadfc769bfcfb084641e7), uint256(0x21840aab39c15380610246a7d724138904068cc5adeff4a4e7b5cb7530f10152));
data[192] = Pairing.G1Point(uint256(0x1afefd0e3662592fc1d8d0920aa97df073c4904e8c0e0fcf60b12104eed482a2), uint256(0x03016ef4808ade284ee5faeb211a144e9207031f2d659cf2cca717400af2e87f));
data[193] = Pairing.G1Point(uint256(0x0d16c23e0428cda2eb2ee9724d6314cb75ebe452c840c787a005ce0c6f016c33), uint256(0x1373b9831a7057169cb1df2060881d7e9a287f52b4a8930e0ecd1183413252bb));
data[194] = Pairing.G1Point(uint256(0x256c79c53e82c98abc8a06d1780dcd1fc0a1be0da9149907748da9903ca618c0), uint256(0x10d720197efbaf2c1e8507b75a81dccdee67bc6955a89ee7b3ca09f84ce5f9b2));
data[195] = Pairing.G1Point(uint256(0x0af57e506cc3a40b77337633282f2c4a63dc8e8837b728aeac6dd3d2075f0bbe), uint256(0x11c5888916a68ecdf4a72737b8381a93ca5ff5bd042fcef7c5787546a1c5ae57));
data[196] = Pairing.G1Point(uint256(0x2d27206db9271f3204efecd93b9f784373d925774cb965dbb7ad791c1a6773b0), uint256(0x12302d0aa77b488c239ece03b50d9bcbe231b21eec5afb896e8f90e0a8ec979f));
data[197] = Pairing.G1Point(uint256(0x022292471fba464f365daab06bc10a4a5b469e484d718eefd54968d00bea2f1d), uint256(0x2a82a29135aeb0e2465766941528ce4ab73ccca635c625dd3805cc4fdc738590));
data[198] = Pairing.G1Point(uint256(0x00e5babb2f9155c3a69a6f33c6ff431e9d445dfc29e0a279ae19cd7487a24579), uint256(0x0aa411e87433d6918978d0ceee5e6aea510b925f5a93e7996168bcf38d698cf8));
data[199] = Pairing.G1Point(uint256(0x0714d27965f30c0d77dec18aaede19f404fc060cc5f977746a75604f25d4ab45), uint256(0x2b736a07ae3d97dd7d0fa141506c14db42c7ac17ffaa1b741690198c946809cc));
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
        Pairing.G1Point[] memory data = new Pairing.G1Point[](200);
        data[0] = Pairing.G1Point(uint256(0x16151f7e9cd6859527b548e594baf5130e8c9f2cdc05c19cee5cc2ea9e8fc4a2), uint256(0x0c6c229eca6d3e90b3507fa04eaab6ff3727bc37bdd0ba43eec2306322b8eb2b));
data[1] = Pairing.G1Point(uint256(0x0d2372f0f64e9070fbd5016ab426b3ea016b1c1755947b3fef70226078a2884f), uint256(0x0086e20f1f3e15c0be944ade963ebb6eb1d5e3749ff9d88e82c179b50add2b30));
data[2] = Pairing.G1Point(uint256(0x004140885384dccbe44de88f7072cf12556bc0e27114c9d3fb91c1b445507570), uint256(0x24b930d17eb5c2741ab21edda5253cf8e86074ee7cec60fc88c5d215a1c28229));
data[3] = Pairing.G1Point(uint256(0x0bb9f28274942486b5c930b8c994cffc3230286f485cbc8de2d55fbe4d5be8e8), uint256(0x2fcfb2e041ade606ee5f77597b455045aa3071c422aaed3575fc20b320d23967));
data[4] = Pairing.G1Point(uint256(0x0721f087be0f208d8c93aa65691198cbb3f9bed76f7c2d81ac6305e30342f3c3), uint256(0x2c4c24d91f4e4cb15ff8e5e4b4a24067099380097844234a09f6c09d35d5845f));
data[5] = Pairing.G1Point(uint256(0x1902164ca6f864ae9385c4544ffb0e59636accafad53dd355206e22d83a4fa15), uint256(0x2d3d6934f8c821e31686cdac973919ab9bbfa3bc265d77d5805fd9da08bda400));
data[6] = Pairing.G1Point(uint256(0x2fff5df9dc7859800d0881c8d25156dd29f14aa3b069b524a522dcdf84132f48), uint256(0x26b46332017e802f272de90d01ee94cdcb1e1938f92cbff1a18dc2c618132ff0));
data[7] = Pairing.G1Point(uint256(0x27dac866bd793dae15427cc517d9360188576481325600b313062e378e1b9ebd), uint256(0x1f77c364f6b40e3776fcf664badee51e6d43fb878b84fab1a78e3f162be26fb6));
data[8] = Pairing.G1Point(uint256(0x0402ab11d8131bba443c4371518aed571062f8e80f10a1eda8f5f3df4b9feec1), uint256(0x16b6948f2c8730f6b59b00d9ed84668ec74972fcf6275946a15d7e4c488d8898));
data[9] = Pairing.G1Point(uint256(0x26d132c573b83749724db6af0e20271ac3e17d445b9689886fcb6df0862221bb), uint256(0x2a73d633235146ac13d40f1e51b391d86fc335a7545e78d0a7581786fa60a67a));
data[10] = Pairing.G1Point(uint256(0x20373296630a813a8efd6af859384f22dace7dc91ef067e2285760c4f5b576db), uint256(0x14b5cd1818f4df98c5a0c213cef3bb7d05adc8db8786775ba95a8a836e0de1ea));
data[11] = Pairing.G1Point(uint256(0x064c8c399fcafc9c15ec14a567473b3a235d9f7f4708cc7299668576953db81d), uint256(0x126e73dd061fc6db04114e216ec32fbdd81b6e5712397ed0300028ccaa3bb9e6));
data[12] = Pairing.G1Point(uint256(0x1fa645f0b6e0f5247c59f9ff38ef14ceb474fce762ada98484525df5d990c12a), uint256(0x0e7d860aa8d6ab1ac5caad2a60cb32e2346eb3f2b2b6fedee1a5d8ba853cf52d));
data[13] = Pairing.G1Point(uint256(0x2f598e592686f7b4f6810eeebe3146ccbb57ecd7ab96c6a5c07d664484d68802), uint256(0x29a960f16f3b7857bd2f9983102484fc03c919e513b5fd43d50c8f2ee6612d2a));
data[14] = Pairing.G1Point(uint256(0x118fb81463f7c8e68c311a456b2863a47ee0e2900584068d97019f00bd8e1312), uint256(0x0805f53fdf0365228005e1e60ffc83716b8d8ef1b90519bf595d375358af49d8));
data[15] = Pairing.G1Point(uint256(0x2a8ac43e0d25a2791bb27d9133689dc7e5baf2828a546e063e1036964dd15480), uint256(0x2cffa28af7f62050cc3b351a116eda55b0dda5db9a4931520300a7b7d01f5ec5));
data[16] = Pairing.G1Point(uint256(0x1c7893f7f73cd97ab67c7c48d71d030f49b9a1fbad29015891e151b6f6dbace5), uint256(0x0f2ef223608bdf44cb7885a135904ba9d108f071c093bdf6c252277c229636b3));
data[17] = Pairing.G1Point(uint256(0x27266696237db3d1505a725f8b04274c56c6ba29d3ce564b9e08d9793615457d), uint256(0x09f700df285ffc991b50d25f2fe0839135a6ae819cc5351d1051d58e9b88cff7));
data[18] = Pairing.G1Point(uint256(0x13e19f2a8f6e4160b9344a806bf075d7d3128bd4a00e9523f54d0de07201e8c9), uint256(0x0194e368170ca68c9bd4200ad4e1bfc6a91748f748a54e097a15a9a8c6d938b3));
data[19] = Pairing.G1Point(uint256(0x08eb1e474cc21138336fefd1deba20e5ffd209d759b9cfd4e7b6edafcfd3ad4b), uint256(0x28e085cc82bbcc8552ec73678115173c7ff958eb85f5546b602860c50c5cb4fc));
data[20] = Pairing.G1Point(uint256(0x228910a8708b15afaa8272039a89f016ab93a4c4eef06f27d959a0dae40b7522), uint256(0x19c64f477eb47a61a6bf31d09f1388ab6f1967e0c746c4db38f760b5a82a2592));
data[21] = Pairing.G1Point(uint256(0x27d7a9bfa4540c47738ac4b8333805398199fef519d096f5db7e701efc69025d), uint256(0x1b9d566d4b4f48aab67ac558c5478c6f54f3e91b7ed051846b50aace8c9f9e54));
data[22] = Pairing.G1Point(uint256(0x049ae3c887bf4872b2abd0db130912fd2931cdc909d9fc69b93c8ca7dfbbfee4), uint256(0x0fb00d9e75f0751b718fd5079fdd2ba06125f26664c67227bda0c007b08877ac));
data[23] = Pairing.G1Point(uint256(0x0f8dcffd286261a0b1769630ed67d479bef4bec5d5037c506472b6103b81c639), uint256(0x003d9ca57a85170bd20faca68cae1f580ab86c241887f652d1bba79c9ae464d7));
data[24] = Pairing.G1Point(uint256(0x11dca9a251b6c1cb1d881224234613f4526d701858a4b06568bd605aa81e1054), uint256(0x1695cfd4ce2146dbaa23b9d7c462cf9815fa3373dac0e39d308fc0073b69693b));
data[25] = Pairing.G1Point(uint256(0x28c1ffab94c0658f4c94ad05d5280c24a60e399b44c48f0f1be551d30212347b), uint256(0x229e596fe19335aca28e19bd48549b12b4f4f148f78bee2315cecd4956c1c05f));
data[26] = Pairing.G1Point(uint256(0x277fac9755eb75b9bb0ec3544c6e885808368ca14ab05b3b67736a8707e3d3d0), uint256(0x1a2d2d2f61cc847663cb59a5d90ae6bd9cf68bca3cc316719fff40838677d126));
data[27] = Pairing.G1Point(uint256(0x091874449c6d026cc0a8e54c710bf19879fdd814637eb9cdb4ebca08b5eb272c), uint256(0x20fa66fc06619f5d4d18c5df9fa5d52473e3a42e4694db3a748fff6b9de6ff69));
data[28] = Pairing.G1Point(uint256(0x078d32978b66299aed471c47eeefa630e9cd835d55f0fe1ef65d06779d6a9340), uint256(0x13561c194aa7807a3bd9a3f040cf25c3261fee5aafbe4b74949c6deca77785f9));
data[29] = Pairing.G1Point(uint256(0x12c7471784e62fce9742e6a9f5e728439cdad607fb17b5d61b3a37719c08a153), uint256(0x1e2bdfe86d49743c063614ed82bae48327795fb62404f9068134bc1329bf47b4));
data[30] = Pairing.G1Point(uint256(0x262ff43c623d019a0ee57a7e125d9591b4f6eb0c9d2a1819d4990c775b4da53d), uint256(0x16429135fae5d38f5db3df8256eec65b9f15897255f25d899635d0bd60a3aca3));
data[31] = Pairing.G1Point(uint256(0x0529a8fda116cea1f0bd46f7b38b1bedd579d2e7c32002414e0b080a4535cd13), uint256(0x2528cc40786f3463a0ea30e88b39c65ff88e59b59335e501c524843fd34a5c7d));
data[32] = Pairing.G1Point(uint256(0x0d3be0a8f980560c6a31d621b10f1321b09be8be1808db8cd7b76aa23be3188a), uint256(0x071c68dcbd1e2f3537a8cb2d9e0553daee441c18f743afb39ab73f405042288a));
data[33] = Pairing.G1Point(uint256(0x0d27ed014b5e0c6f326c62087a3d0fbc11853c5ebcaedcb1f170c07003e2c80c), uint256(0x26aa84dc13121d6b8736b62491cfc866820a85ecbbcc356172a8edea07dd8eba));
data[34] = Pairing.G1Point(uint256(0x20ca722b24514a1e6560e1857702ed863de59021b6ec52bf485a6f0ae0dcbda7), uint256(0x1393879c79e305d5408ccd0827d802c0e87a3ebacbf7a6d278d4d34f62dbd3d3));
data[35] = Pairing.G1Point(uint256(0x2c170551b699bcf02bbaa68df5eb1bb1e05a7a48236ff8bc19255a067acba628), uint256(0x02452692f43345ff65ed143f42aee45fe057d136694c0bb5ecac0468faf24fab));
data[36] = Pairing.G1Point(uint256(0x278ab73073253fb8b74442e9d390fd1df0b6e021758b29b16f7a2e1d795df00a), uint256(0x18ddb9817c076b1a939e03f54c0d30663e8ecf1f6f25a2f449f50763681e873c));
data[37] = Pairing.G1Point(uint256(0x149fecccc31a60923eaa6694477fba2f085c65931c390c34a0878d76e223ea29), uint256(0x0b778f876b708667d3b8497797f7de27d544c655a9ee0197dbbff2a108e5a074));
data[38] = Pairing.G1Point(uint256(0x0b317e5a07270410e53fc06274944d912bfb18dc783ba243bff68587b6a6a37a), uint256(0x27e71bbf57897229711cee5ad8de13d0099df96b86056e12d8c30685bd66c50f));
data[39] = Pairing.G1Point(uint256(0x10121d3f52f72419460fa0b4da8d1ac749f9ccc9f7fecbfd37baa37057d3729f), uint256(0x132e493ee14c5b77162f3d26bb7bb499f1cce3547f3dc529180599dd4fe123a0));
data[40] = Pairing.G1Point(uint256(0x2d80308a80035d2a1cb9b62c5cbd6a22472ca98704feec7c5d8b08452b6ba7b4), uint256(0x11bbc8946cf2f823bcdd7a564fa9b1f3f094fab93b92c0f0b9b15321904d6172));
data[41] = Pairing.G1Point(uint256(0x29316d1bff791edddca9e5d1f1f4a60252bcf006f72a9ef036b7b14bfb8e3290), uint256(0x23ad887582aed2bfc456028dfe58c80acca3bcc7623518cac081b132e9ade0d8));
data[42] = Pairing.G1Point(uint256(0x1afc708ab382b99f0ac6ee37abd54e5ea5208d8aeb98135d8782a71e8aa5ea2c), uint256(0x13644d767d1a04bd3f504c7919743823a1b529c5558e50acc5fc1ab6be04c35e));
data[43] = Pairing.G1Point(uint256(0x2d6f4accd287dbf4c02c923dfba38939e3a242f1e4e1d43234968e0fee0e527a), uint256(0x01a11224c9ea5171a06470269f9af090fda9046eadda07502a631405e26571b3));
data[44] = Pairing.G1Point(uint256(0x09f6958174d50cac44fc6918e737729c635933606bcd226ca1fdcdab0b89f276), uint256(0x0b88a1c38d01d65b2169baa34d33b09729c8f68d053368e1ab99421582ded5ce));
data[45] = Pairing.G1Point(uint256(0x07e3ad7d8ee2b2480cb51c86b01d8f2a3d15221be42aee5bcd51c602423e5665), uint256(0x2226d0df4dbc57f5b216825d2f9f7d36cc049991a84270743821ffa516daba69));
data[46] = Pairing.G1Point(uint256(0x161481a1a218c83ef38bb602c00bc2f264a2ec681115559ced31113b3a22f9f1), uint256(0x22d7f78d0917700cad9e909e947fab3b590769537fa6b64436a411e1f018147d));
data[47] = Pairing.G1Point(uint256(0x0731a93d8ee05ab0182e4dfb5f96a53809fc6a2f1511b4e23f9c36a1a0080055), uint256(0x19c39db86d89abe51a0a4662330c35b8e05bb981110504dba50787a560bc4d9d));
data[48] = Pairing.G1Point(uint256(0x172ea42805c1ea5c92a3677bb1815f75ec6cc94f5cb69ef01d0c398ec19df42c), uint256(0x1073ccc79a26f2138edb4936e9a344966802ff4f65ff26d85c4af5e179010cba));
data[49] = Pairing.G1Point(uint256(0x1df95859f375d98dec42accadcd181644497844e4b91740b887909b71e613b6b), uint256(0x155670dd05b7af3881b57116e8e2b42b8557d177a213190991c18b34443dc077));
data[50] = Pairing.G1Point(uint256(0x0cf26c4b7432e774f02e18f115b26e668cb64aebf82f7e8cd44c35e66d91d050), uint256(0x22d29d148a0b381d79f6c738e49627a6a49b587b962167e4754d5416602ea4fe));
data[51] = Pairing.G1Point(uint256(0x23d83b4f9320c33770c84fc3dad89f5cc1c213e8732ed75c5b21575795814db6), uint256(0x279f1315c94246d76b4dc1644cd9e6b607e99822c30036e26e654e498d21851b));
data[52] = Pairing.G1Point(uint256(0x06805910b2f02401c46fc53c9898d517e71a773b447b6b2cbeefa1637ecb4a08), uint256(0x2e781d9b6d5cfc4c6bc0920e9ca0b8966ad860ed18e9280bb9f310a385c799f2));
data[53] = Pairing.G1Point(uint256(0x01026f066ac3fe8e9a0cdde9bfafc5799b8f20f294a770b83ade9b66fd4fcac3), uint256(0x2714c1e11ed858cc9fcbea96cd2d0b8947b46990dfbff8424597635da48925dc));
data[54] = Pairing.G1Point(uint256(0x1b935e62f35265e6bbd5622f731c7c8f9fd5d108dad2e380f2412bc1b8bb5541), uint256(0x1774cbf0330c6f3b9456ca381a9fd1ad7de00386f1f030a4ce9bb33d9c0615d4));
data[55] = Pairing.G1Point(uint256(0x2d4fbf0fa95767dc480dec7eb4cf69d5264d7c2f40448fa078386d2651e497b1), uint256(0x08d9d788e5fb2205b32b5a0252b3f3fd1ff7073b912ddba03264cc276b07a8ba));
data[56] = Pairing.G1Point(uint256(0x1b876e8e93aab7c7af48dc43e08b895a9c4408a0056f9f48c6eb2d6f18e1925f), uint256(0x18b9412d25d15ac84eba36e8f2f8f747e0837c876776a83d748f67d938cf4bb7));
data[57] = Pairing.G1Point(uint256(0x0c3309ebd44a620596ba14045822a495866ff46118f0ca581bde5cc8630820fd), uint256(0x05b7f45a5aa1c1b5fd197296d567bf9179441e6e2425ff0f84d55b884153c893));
data[58] = Pairing.G1Point(uint256(0x148b06512d6fbad6f18d9d7ec175b199ac9cb2648f1b934835f023866f1bb6e1), uint256(0x230430a6fe63634c267da569907cbb59005a440bb0cb9ffed14eda38e2ceac84));
data[59] = Pairing.G1Point(uint256(0x15c592982054e6a0e02582cd97e4418b05cc492ad42e140c5bad13afe8bcfe03), uint256(0x2ec3c196f92eccb25aead4ab20c414573a41534451729afd3ec6363ae875b8f0));
data[60] = Pairing.G1Point(uint256(0x07bd5cf5fe1508bef318c79135dd6d5360bbe00adf8524de4f04a541b25454b9), uint256(0x18eb4530aff9d2a07ffd688efc8ea7ec156a72050560c7533122193456010cc0));
data[61] = Pairing.G1Point(uint256(0x1f94bd5ed0d3ea824931f9db38147d7e348a6debdea1b3819468d7228c472c9d), uint256(0x2642546ba5ab710518a5ed121ad394baa0c583aa0507bbfc9228f4bccc839a2a));
data[62] = Pairing.G1Point(uint256(0x003d45e94bd86ae4f8f17491a00bdf1f859d3fee14e6be144e1cd0ae87f3ffd7), uint256(0x2454a4b378c6a223b97c21b9aa31b1a842cec2e2f47ad2190da9f46b213e8060));
data[63] = Pairing.G1Point(uint256(0x0e06abafa2f354702cedb71d0248eac742f6ad239034fb855ae711b341432d21), uint256(0x2084ef88408b53e1612328d23d896586353a6f11229323af0b66608b5d3e087e));
data[64] = Pairing.G1Point(uint256(0x1e2ce52f276cbc665aef32959d4b447fc60859b6e02680c3ab38951c4b4fcbd9), uint256(0x0440bcf1180b56a54b8c3ac38d7f2be147def9f45067217f7aa55c33d17274eb));
data[65] = Pairing.G1Point(uint256(0x2d347931d0c7f1ce69331654581c7f8865032523c009da6410ec4c3f00c5fb0f), uint256(0x2b634c5cba1ff41982f211302ee5c0e1468dcdae073abd01bff94bdcca12c57b));
data[66] = Pairing.G1Point(uint256(0x1cdcca98c711d9fb1abfaa1689d76784846d5c7d9ba1d9b31f5bda02f939cf50), uint256(0x0d67f2c2aa158a388906388f95f4040e5492fa36cf00b837ef34e6848260d52c));
data[67] = Pairing.G1Point(uint256(0x17168048ae1abd1258d61abd616e87ce96e6b618cf9513c80fe1e510236b7c3c), uint256(0x21b5cf0cb46b7c81ee18bd049e7e2c1ec794b5bba8044f7f366543cc4bf4be1d));
data[68] = Pairing.G1Point(uint256(0x1bdb9a015da86a9eaceb09a2664e39224bc87f1c761e6b64b46407cc453047cf), uint256(0x099aaedbfc1f026cbc189d6ec6a16c601eb658d23b543ed9fb0bf1da0f9ea33f));
data[69] = Pairing.G1Point(uint256(0x2c27ff253d78306e7a30eabb2661bb9dc65a0cf18b15ab7927e26e6c2aa9dd3b), uint256(0x0d14ca4934df709ceb881ebe196f5e2128c60c7010f999992094d273ad8e4578));
data[70] = Pairing.G1Point(uint256(0x27e5fb9d073348bc6bb30085a9830e3ed84f3036a58677951949bcd9e7892b74), uint256(0x0e4f09d023641df99a4aca01070a11fc7b49c5127131c3bf113b739de85c9104));
data[71] = Pairing.G1Point(uint256(0x2e071cd0fa13a7ebe27010d2bc0cf27d87da2becb10601772a79a43a40cf9a99), uint256(0x06b79ca3a4bcacdb4f3a51aef37f3ef14980e4c654b27394c8a05c43f9ebe996));
data[72] = Pairing.G1Point(uint256(0x0c636d34e63be870a9061b0bd1edeb789d9be52e9913c585e8294df85f09bcff), uint256(0x2ae14d1a8261b0bc12680b57cce27acdcb9c893aa799f0e22ff1229d2151bac6));
data[73] = Pairing.G1Point(uint256(0x133d06b87297479bf5ffd93b9db7a74ef3adb4906aa6c196c9c3a077d418b473), uint256(0x1fc83c3cfda535faa2c3c7ca9f7cf4a5086d1a7b768ced3a94311ffc64f7ae3c));
data[74] = Pairing.G1Point(uint256(0x22cbb2f5eda5a98526231fbee80e890633825fd97b373493fb7b05b6e3de6456), uint256(0x062c2ce48ab9d552a63326b24b9f5b54f0d19dc5259bca3f53d231c8215a9d34));
data[75] = Pairing.G1Point(uint256(0x2917698116c7846c4ee37f9a0057635f1cf4fddb23e9c03b2b7b20a09ea29606), uint256(0x12c8d719b0ca93df3a92602bc7536d00e7bd4adca2378c9cf3d65362155fe604));
data[76] = Pairing.G1Point(uint256(0x04ac3113ce399851bcf8b2b4cfad9ff8d9b0dca62dbdf85d4d016ebe115a5dbd), uint256(0x1775bd1ca887938c714ccb6e087c77f2b914e504bb94f4f7428aa45292fd55d1));
data[77] = Pairing.G1Point(uint256(0x15977287c6a2ad981fe8606bad875a2dbfbed8c52c5a3b25fe4ea1e767d637e4), uint256(0x2e016d0a48b27e835ff47c52016f2a27f6c985f5a08e0ad7ad52937ee1442ff8));
data[78] = Pairing.G1Point(uint256(0x089f9e8b68f732b7199881b65ffcb4efe36ede3b741bc76fe77267fecb90c719), uint256(0x0b2a00fda832120a117cae6ca368bb8cdbc199d66ef686f7de049cf5a33ba37f));
data[79] = Pairing.G1Point(uint256(0x1cc3a05409d53a1dc81469cc743b54afc8c952d4ade34c1de25ba69a7e8a07fb), uint256(0x16417faaa354c0c373e2b2006396d89c2d9dbe2ec10f7d98bbccf4ffb07ffbc1));
data[80] = Pairing.G1Point(uint256(0x209f4e64c97ef6ab7543e6d70254fda314814c9a3d14d7374d1694010a9a4607), uint256(0x0773900d7e305dc706848dd43fed989feb086679865d42bd325fd7ce94e6e8e2));
data[81] = Pairing.G1Point(uint256(0x2e7fa6d23c9de94debadec9d2081dd1516d6c6ff78c2f2315898868dce2e1a3e), uint256(0x06e854525bd6ce59a6ca08a02697d03b95bfaf4a017a20fec758169d68cf13bc));
data[82] = Pairing.G1Point(uint256(0x2c75b1a975f9511ccd3e884db6b67249cd2d0402809140421b2d5d1ae59de90c), uint256(0x185b651d4af277e9f2af5da494fe9c65a48800789b4883c0e7c6408f4308193c));
data[83] = Pairing.G1Point(uint256(0x0e8f7d29007b83ff49fb18f22360261ca06663fa0eb3ce4e394998ae1eea7dec), uint256(0x01709d93d4283ede2ae12ed586a456397ccd8f792f1901702161488ca3da3dce));
data[84] = Pairing.G1Point(uint256(0x16a32c662098c0d8e254ead2c8131bf88a1ed64a25bfcd1be02368adf4da63ce), uint256(0x2a8e1890cb88533a6f8d81c326eb0e93296dc6a6a392c3372f678cf34067af77));
data[85] = Pairing.G1Point(uint256(0x07c9960d9a1009255946988a4738cd780ac2d273a14f3a94a617f0c8dc2df590), uint256(0x07237e81e290c7bbfd6fc8fc448867bfc82d35c9b6afbf4d9fed3cbf76910859));
data[86] = Pairing.G1Point(uint256(0x090d2ee435859c68ab7c3f5182f294f129f6107d56c392d93782f98abd0eae7e), uint256(0x284bb26894ebd9a2626835d56664c1c93b96ff4e33651f8673c82095023d50dc));
data[87] = Pairing.G1Point(uint256(0x230f3448d5099abe7c2a97a149791a5ea584f30e16bdf49c064b3f8142ecc3cb), uint256(0x21d6102b6dd3045cbc9b97807166eb3aacbbecde70ee047cab4e65db71476469));
data[88] = Pairing.G1Point(uint256(0x23e032e48811997854b618011d8194c05173a5794cedde43d26b4434b9c21dc4), uint256(0x24ad738b026e9709cb4d11e38b5c9ce1c4ba69892cab19cf998cdfd79fe53d2f));
data[89] = Pairing.G1Point(uint256(0x1768e571a9eb190f9e4939076f33d665f8057cde7259cd7a7ade70c013cb280a), uint256(0x147ad9707057d736db75dc4a99caaf3f6c6ce04c40516a1b0e8c85292ad1e264));
data[90] = Pairing.G1Point(uint256(0x021b89c6d404df44b62acd888db5a5a901a8662472ede41c5e72cba5456c6ce0), uint256(0x0fcb46a400e1394f762455f414ef28974c63d960c9a1c9843ce5cd8ffc45ad8f));
data[91] = Pairing.G1Point(uint256(0x27467d680f464ab63277e0d592b6558a3e1052a94cce54b6a5f509bc9f38573d), uint256(0x0e39861699b90b1faeb684f24dbd8ed0c277480c6066f91fc04d16caf7c7acca));
data[92] = Pairing.G1Point(uint256(0x2c880e1339fe423efc1af06ace304054f5abe34558f98b2bfe8bb7d0bfcc222f), uint256(0x25e61d666077f8fd37b747103d2ba94ac1e4aaf04d53a673ec30871d05c4c0fd));
data[93] = Pairing.G1Point(uint256(0x29086ba3b9230eb019da38726d271fbaa9a40f9fc4b37dba309f258e2326d90b), uint256(0x070af8e7029e8320ccdeb5a15def655f26f5740fb7ac3fb4faa45d4b6c99cd36));
data[94] = Pairing.G1Point(uint256(0x2c078167a5053e38a34b9d642887b08aa189416746d8505e65424e809e64a5de), uint256(0x2eb063bdca1863c368dff5f05ae08a0cddd9171cd84093f7efad9e21eac260b5));
data[95] = Pairing.G1Point(uint256(0x2eaff076c58ce763234416c503485b868ce5803792fcb5b66dc827d3b6c712af), uint256(0x181fa76b3a62f1293139783f8e213cd9b1d3b9f48366cae6fe81a68b298917db));
data[96] = Pairing.G1Point(uint256(0x246f4c9ebedbe5319bcb8e6797e30a800573753bba21b703b1d34d23c0355f6c), uint256(0x0622101b29b83da82152f9c0589d220adfdcd1e940486f8efc5ecafd964c25ef));
data[97] = Pairing.G1Point(uint256(0x2ea49eaed64bfea17be915b80d1762b4d6431fe1397e6c551e87ac3298212a33), uint256(0x15274b746a10af213c873045d77b5a8dac98935c6aaac00e24f8600e7165dffc));
data[98] = Pairing.G1Point(uint256(0x18fc943daeccc313481108c9d72ceb3dae56dc3f1d4e37afbfeae415a79cce5c), uint256(0x0834ce3129bf7c2b6d78f5d356c2183ab8e219df4f52e8139bca1ff38130fb71));
data[99] = Pairing.G1Point(uint256(0x123084fe8305b6acf3537bf93a9790e533742907658319449ce8b4c971b30b99), uint256(0x1596a6ce455012754937554cb7e4d5e4e6476deb39dd3925d73664578c81a701));
data[100] = Pairing.G1Point(uint256(0x276b3731d140361e2b85e17f7652039af7e0821d68b540f0ee81761dfc28a3f1), uint256(0x002174d7f5bb217e7dd8c4d4defc8e434f9207fff83965307cc28ae5a71693b6));
data[101] = Pairing.G1Point(uint256(0x1e690206374c9f13c72ca94508d8a04daefeb29f62a4a8f3bc20d55ca065645f), uint256(0x126f68ae7df0358b2033dfd5564d707e99843653889748a49a21e9739cedb6b4));
data[102] = Pairing.G1Point(uint256(0x28bf31b02801dcb91bff60d2fbd4e0753e6a7de8afd9c5c502a9feb65e0f61fe), uint256(0x0e6c1a18e69576bfa4ef085a34addae2a6676f97ef2cac7aa737af82b7e65298));
data[103] = Pairing.G1Point(uint256(0x258c602cbeffcd45fa9a7149b0d2bcbd688c75f58cc696ec3a0168ac97f1da74), uint256(0x0324bc1ed4ed88a11cba3ae0098c7b5d34006040e4333e754933f728890c1b5e));
data[104] = Pairing.G1Point(uint256(0x012eb0051b120ffc4c5d9e04222377f5e4495ab253d8fe8f3a471033655f9075), uint256(0x0384988753805faadbee5e476140bc54b0ba50640c62562b12ca0ad3d7df04ef));
data[105] = Pairing.G1Point(uint256(0x0460ed9407884d05ee07f15530de053f3611c3a63b3a06ac782a51b7622b74d8), uint256(0x27ddbc95cb0057e909744b85b8e3ac9e64d8ee81b979370d585c30e2ba6f0bdd));
data[106] = Pairing.G1Point(uint256(0x0b398c31911d5f554c61399c6ca49b4f1f2eb7731a95c72fc6515bbadca5a486), uint256(0x181befe203f071c113617e3e8e22b8d88a2531dd605a915864b4a945028cff0d));
data[107] = Pairing.G1Point(uint256(0x281f57d478aceff32c78a7ebf37d8768ccbe819cb905c82bcb8af6a1cc157936), uint256(0x0a4027b16cac822bb0c2cc4e8b57b7e3125a081964b2ac6e38f41516b0278342));
data[108] = Pairing.G1Point(uint256(0x099d6b3335cab7c54b44baed063482efbc8fae0570c05d84c05d45a78c5a62db), uint256(0x050a8951add26571f2d2c1578c3dedb684cce19700d7774475a9c68860b8c4c6));
data[109] = Pairing.G1Point(uint256(0x139a38e124aa588555e6e068fd6eda360042afa4d0e5b71330182752023d01dd), uint256(0x239a7965ed4f63c66a03958c3ad2b1e1c0bec528a85352981599a8f9ef256e3e));
data[110] = Pairing.G1Point(uint256(0x277ec6e75ed9489afb07e9ad5dfcab358dafe9ebfde4ba8826bfe47484587991), uint256(0x2c74480d95e99c1bcf5a1463fe617debb984152e6ef017c8a73a4722341e955d));
data[111] = Pairing.G1Point(uint256(0x03fde3c1133059595af93abbd4931c722cf94e61c55111cc6877c0533842ca83), uint256(0x0466ed40d96090633d88cb3fa92a20e76e35a89f44c700a3cf8fe1cf4cb074b0));
data[112] = Pairing.G1Point(uint256(0x283b3419fc2fa9ebe000333dddd73721f3c51c47a1a1dbbee043b9aeca059df0), uint256(0x26b8899c2576fa1075ebf5f2406b5bd678e50bc44acdbb81a34156c41fafcc9a));
data[113] = Pairing.G1Point(uint256(0x0c0505e2f86ea4324d37e7421ad21b21186e1741d07f02bd82bda8f259ad5f89), uint256(0x11e7c89181baba2e1bec74a50413058986286669518889bbca248a5d2c65904c));
data[114] = Pairing.G1Point(uint256(0x2003513a957a697907d4d7bd8cf18b752b901848dd321e9f32af5016d7d003e6), uint256(0x21a991892fa4a74ad10c70552f0fbd444880a0a4764d141266e21508a3e5975d));
data[115] = Pairing.G1Point(uint256(0x2c295fa1d9eeae30a3bd82e844629d95a7a71b2691072bc157108543951bfff4), uint256(0x21fa2c07794d1a5e10fa4637ab98d11a299ad48e7d0eb79982ab5f7b9b872078));
data[116] = Pairing.G1Point(uint256(0x11370dc4c831f05cab225cb6b56121af2dd093a750e3fea295dda28ade63e5ed), uint256(0x1fafe15cd95ab7034e142069c040fdaa22f1fd80498eeb5ff7691a8b899299b2));
data[117] = Pairing.G1Point(uint256(0x041eebcde43cbd34a16fc7b3f68d0bce2ea523df6b0896080b2cab6e7561fe76), uint256(0x2123baa684019a451aea968627b1193b4c60ca5beae8f827e57ebc44c2a1fa0c));
data[118] = Pairing.G1Point(uint256(0x2fbcaf508dffbbf13c1842472ce3ba545e4234a826df4ea059d7630ea59b35cf), uint256(0x163f5d2d60a054e2217e8777a2a56f46315a952e9e6dc768104d8799f2434dc9));
data[119] = Pairing.G1Point(uint256(0x10ce40e1f64110e80d93d2d688c8ba8ce3246408843a45f594fdc4bd886a7e4c), uint256(0x0ecb4ddf33b2bc146ffabe966bcf32e97678e22320e264e5ecdd85fcfc330b92));
data[120] = Pairing.G1Point(uint256(0x16de35b3862a4abcb694cef116c1b61d73a5aa1d33501367e39add5027a02487), uint256(0x1eab42935f61a1cac8950f9251ce2d9b42f5aef7ee590a0716c42c632e992df8));
data[121] = Pairing.G1Point(uint256(0x186e4502dc8abe957b425560ae799ff365ca2546f9cfdad51cd8a635a221ea25), uint256(0x018a5e8c827db849575e1cff4d42fec5aa7fd8498d5d2d76a9976bffaf1ebe03));
data[122] = Pairing.G1Point(uint256(0x1cbad0b9b6f3ccbd21784943963289191f34f4ed9bc0a852f20b4f2ddbc6cb3b), uint256(0x0f2498c370c9ec86814eed95fff144471cd884e4838287ce729ef8840bbe1649));
data[123] = Pairing.G1Point(uint256(0x2102117242b444e60ecdd9845270191fb1c03fdd55bad9e453b4263f772f0037), uint256(0x18b7c1a8fa4187bb7432c051f84901fec50194dee9dc9372d9be417e5fbdff46));
data[124] = Pairing.G1Point(uint256(0x088be6fa8f4a7156bc5988bd397aa661a37783c6f2705d2f3bd47a5a7bbb1bb2), uint256(0x1cdfe4122cf19d759ce02159e51dea82f88daba6a20f6f33995573a9823b5f28));
data[125] = Pairing.G1Point(uint256(0x04f63ed76b7c52b979a870324440c6aa1950f0f791c93e6acbd8e62071c5cdfc), uint256(0x1fb74a4e3a9967f06a0c575ebb44d86696fd9a5b2a6ed3fc6f4630398ffbdea0));
data[126] = Pairing.G1Point(uint256(0x231aae40cfed6fdf40ef1f8c330765d8eb6671e1f3fee82e9149d8e953ac9d3e), uint256(0x286c424475bee609b14b46eb97bfd19dde5050089d49fc5735036a4c04f8fae0));
data[127] = Pairing.G1Point(uint256(0x0a4761c1f4a9b0ac137340445cd749e82c4f03d45ab6b9d018ff56fb7f261663), uint256(0x266d031cdd63096f4d065b38c449a03258dc9a1fd5dc3f4fa2ab8999d0a81b6c));
data[128] = Pairing.G1Point(uint256(0x2ba7a14f1fafc9cea4b62475b57d23f6d2df26145cfb6451fb092a224e38166a), uint256(0x2e0db15dfcb48cfd969a0bfbbbd1da32c7e48e463433cafa43a278e39688c716));
data[129] = Pairing.G1Point(uint256(0x04fc39985dc029d29619e56d9abffcdf69182d850f38fef375d443d672a47d20), uint256(0x17dbc6fb27204888ffeb021316c0a475afc4102cf61618e7bc5063e5f83afc3c));
data[130] = Pairing.G1Point(uint256(0x03de64919ba222b58d183000415bea3161a08d7ba53c808679abff8707fd3bd1), uint256(0x1e6dc193ef49d43021630d0a3ed27c807eb2087f86b3ab620c65c9040cb53aa4));
data[131] = Pairing.G1Point(uint256(0x052cc2151e84eda947a73f630b37bab3993c1172151ebc48feecbc11aa1a10f7), uint256(0x17d3fef27a7f69a40772d04c6cb42c8e8c556dc3bcae597cdfe34596a8797dca));
data[132] = Pairing.G1Point(uint256(0x23cc9af7cf2482a995984038f6b4f94827d22125239de6817cacdf6516bd02e9), uint256(0x0f5e462a072185bb011dbc7ca2e71d30a0e8df7116477548859d7ef90cea6497));
data[133] = Pairing.G1Point(uint256(0x0523630e59e4cea125db3ef73d5a8f0a3f5809aa172fb7930f26b3fa05132caa), uint256(0x11ca80ae19bdbddd5fe0a1e57494d090ee8ed4f1c5a74b4592b29153a7e1744d));
data[134] = Pairing.G1Point(uint256(0x0d073e2aa6210ee2b5c434f8cc8475db1ea17111e22c39d71cc14ec5a42524ef), uint256(0x11f903265925cfac78000ff25cfe38e7f5290936ca6865fa0cdb6ecd0eb2db99));
data[135] = Pairing.G1Point(uint256(0x10cb09f65176922002555e37b901c83853db400f9aa13c89f04fa6eb56f7ad6e), uint256(0x19871c2aaa46e81f82677e0700598a3f3ea19acf659e0fd04a592d4f5889b340));
data[136] = Pairing.G1Point(uint256(0x05d21db554a03c55ef3f3926b13c4543518cc225821f722f654863e43cd25cc8), uint256(0x166037567c7c5e86715efc01b674825f24a4a97a639d6e3479b2ce2431243ab0));
data[137] = Pairing.G1Point(uint256(0x2c5525818e5c4c458b999786c572b719a6ae604631ab50c6e63c8b92b5808b1f), uint256(0x2ecbd06d6f4e40088d9f48036fe4295605c89e8a5c9d720f9c8422f21f38fa32));
data[138] = Pairing.G1Point(uint256(0x2ec482e05f71dd08a52b6eec3f0080da3f605fbe485dbb6ed0d26dc1c33e154a), uint256(0x248ce4f92ef900e3f6b5ce0a1afaa8f6871be4b2444b35b4e8f3349d4f36e877));
data[139] = Pairing.G1Point(uint256(0x0bdf98af0f45ad2c7b05bf75b914c0e148840c8a791278796e86998f493a1433), uint256(0x05dc066588a05b058a392ac2e7e6163a32dea2924c90ee3b14841ffdb6f2d251));
data[140] = Pairing.G1Point(uint256(0x2561d56825de38f9b8d47568f6c94275aed71c8f2a7bacebf2ffb8f4915add95), uint256(0x287980a71d97d899f374b75b900dbd4db5309f428a3e6bb5f5b64e306af1e0f9));
data[141] = Pairing.G1Point(uint256(0x266267cf7f67559ef74d31fe3f7476448dc9f2186cb1ff883bcb43b7bb356c60), uint256(0x0f8a25f0c50a60c0086bfd5b6d6146d5b33006f249b33f4fd6ac3885bb516f11));
data[142] = Pairing.G1Point(uint256(0x08755250913b7c011b8d199e9ec83b12d4e63baa3d40d4f00dd94e7a2081d4f4), uint256(0x0ffba161c1201bbdf5af864693e3440ea5f6d2a67fde1039b536b4c488980a4b));
data[143] = Pairing.G1Point(uint256(0x072e2db8e1d482c07cedc67394dca819748b300a6c32c94ad38ffd2771d0cdbf), uint256(0x230e42845baefada2476f32a437dfadd9d1ac929712623063a3211b4fb684865));
data[144] = Pairing.G1Point(uint256(0x062ade434ba4eaa02a4105ee290860956cb5aa33ea9e22315cc5606b25ca72ed), uint256(0x2f9088b5d48c7d1429e458efc81b0abc839bbd58ea4a985d4c86a342efcedf67));
data[145] = Pairing.G1Point(uint256(0x305b9fdbc0c5f347e4198758dfbdfda50654d1494620bafc80d24047d8ad576b), uint256(0x1b0e33c9cd9323058bd611d3e42320469cae0af66a13b5b7a6bb358c06eca8a9));
data[146] = Pairing.G1Point(uint256(0x13a63bf728cbf2a1aacf49506a64811b3d08cdb8c171286b0aa37d4cd034347f), uint256(0x0affb86d0b46364343e791b758f921c6ad50cca892c415603b9112dd03d4985c));
data[147] = Pairing.G1Point(uint256(0x0d99f4dcc523e1393add232a2a708fba83df6e96acea11606a944d4d36066793), uint256(0x1fefb678f716283bf057882589ff6914c3761e13b40bc905f2fae5b0bfc23cb5));
data[148] = Pairing.G1Point(uint256(0x259acdcd308feb462b6b61183c9dfbe0248a56c51410cfb997b752b2195f2cac), uint256(0x12823fad128e0e289c385b58b110fae45b11df99a1945416333d25420efc13f6));
data[149] = Pairing.G1Point(uint256(0x10eacd16ef4ef311636ad9104d9a030905f7dc657f28f2fe11dcca34ff860268), uint256(0x073b121f6cc740df1e7c9d066704c48ba474c088f5430ad64db88c607d9b6f72));
data[150] = Pairing.G1Point(uint256(0x0ef0c9a2522027916c96d2db00bde374b25b492c6fda04a582f4ff9e4da34afb), uint256(0x085f4c5d00014711d53afb433af4b18ba3cc09b548048fd9a9bb37010aa0be61));
data[151] = Pairing.G1Point(uint256(0x0d0af3acb3d10643ea19bd644e5d32be76ae793af7784522c4b71afe20ac02bb), uint256(0x0653be8f34898f37d7f4a42e129a59427f96f70c7a112f94ac4432ed2ca22daa));
data[152] = Pairing.G1Point(uint256(0x1178c1a4d4be41ae5c6068ad1b3966b3ef53182818f36a8b93b87c7132f44990), uint256(0x2b3b071e576a5a86d3316a7d9a103a74b4e3bea261b8685b6db30f292363efda));
data[153] = Pairing.G1Point(uint256(0x100b3d3692bbdf703c5764675ef48d1b3f230745f41d008a616cea07c2f1557c), uint256(0x13bae66bbed0a66336ddcaac445af25cab08264330c0b80f279991288b05efa3));
data[154] = Pairing.G1Point(uint256(0x1827d6d3974bb3b67ab47ef23368f57b0d91804a8ffe3f56d1485c0ffc258d41), uint256(0x02914b795803e6b067e1335de337eb8ceedd1766dc3863ac26fffbba384a81d6));
data[155] = Pairing.G1Point(uint256(0x2445d6042bb9e9d175531ab941776b725824067d8cd3a2ef4fed472fd150fa03), uint256(0x2a653a66d9486a7556d912fa30d715edf6f25055e8a24d88555b8bcd4036a70f));
data[156] = Pairing.G1Point(uint256(0x0270e79db8c4f2277f12a88b947325d9bd01f14dfbab4b0a4781ada14fe24b71), uint256(0x22cef67172c97a3ad2ba0d5bdbcb3fe48f76bcbe1430703a796e89e770e030c2));
data[157] = Pairing.G1Point(uint256(0x3012b880fb5893a4a21be2d692bb38f9c88b9d94757cce24b802549e71371fa7), uint256(0x05f37b1701bf21063304b10da3712afbbc656fb5846df6a8636fe44194956c4e));
data[158] = Pairing.G1Point(uint256(0x1f95db97985ac24a8448d258ab1520733f6fcc08f8dd6f977d650032ae0ce199), uint256(0x05625b5f897fef701aa8e057f39a86fa8a43528b9d3e1d9c91e09240636881dc));
data[159] = Pairing.G1Point(uint256(0x144c082ff3f0f4ec1efbb9d8582e84cdcd5208a1149b197dde27105bff9e780e), uint256(0x11be43d8fc970a015fca812313659de0a2435d3aeda26338b28ffa218bf4d5da));
data[160] = Pairing.G1Point(uint256(0x01301cd2c3d57f11904d36160e56ff38f0dbff5200259d1b2f9cf124eb7b7b19), uint256(0x09fa17bb900ecb36740048c8df3973990be8acbeb697e83840bbcd0c512658e1));
data[161] = Pairing.G1Point(uint256(0x010e4d057ce0845cfb833f99643625f6f0e64991cbb59d66859db01ef3427fb9), uint256(0x234824e55b109bc6d9475997dce7a822f0f639b9a6c8a5b856d1da43f5e8ebc3));
data[162] = Pairing.G1Point(uint256(0x169117f9e0652e064ba4c31a12c2396a88e32d2421303eb1779239ad6250c737), uint256(0x2963119915816db468ac7ed46f3a37d9d04065aa280952ca88176daa4c899f40));
data[163] = Pairing.G1Point(uint256(0x2b6baa836c1534e0ff4000ae41263ed1ab8e400ef1c5489890156b7eeed205f0), uint256(0x3039cbb9789f81b6db0f66df9c1fdccd3cf4e133cfe5a3eee741976a5f774cc1));
data[164] = Pairing.G1Point(uint256(0x15f478d34253c35c9052f8fd6f209568183770d4ece3a870b3fa145722c8a9d9), uint256(0x2349520923633a48f38567b8bac78da3689c6fff772ad1d60a646adc17ee7403));
data[165] = Pairing.G1Point(uint256(0x1743a17525ce714b0c5ed240ac2f32fd04ac70abf677f7429b62d4d66671faff), uint256(0x2a4b99c2718ed7b86be90fb3088cf3a966de389f183f871f7fa15631eda27b27));
data[166] = Pairing.G1Point(uint256(0x1ba8c067e01c09e26f99339d6b10ec57cd1c49abf5cd79498b3dfe50c3e1e219), uint256(0x0d0c1cb9f2831487b47d76bd96768fe65f19a4b59ffd607423e909578e788d97));
data[167] = Pairing.G1Point(uint256(0x108acabba8c29cc59e10c5b39c9a6740eaddbf78aaeaa09a9dd21e179ab8c36d), uint256(0x2b950008e5747d4f1ce60c569fe439637c17e1aa261569c0af25f39a6c9a817c));
data[168] = Pairing.G1Point(uint256(0x252cf604b15aad57f98d0dd43f2df926af8def91a180e784d514a151cc27cfa4), uint256(0x045b823f36b5d93eec850015806e4c94313e2b13788d7d270395967d267a13e4));
data[169] = Pairing.G1Point(uint256(0x2ebb274830c4935451e219e77a82f9a578ee675d8d88e1ff19f29e795f5f5030), uint256(0x2c5474fe71b1bf93253789bb61e97a1892fdc29edc81e64ce2e19508cdb54c20));
data[170] = Pairing.G1Point(uint256(0x09c790540461a85b173a5d8dd104f5914d0838f6b93c3d675450b18ef68cfb3c), uint256(0x140c2a9faf016bc1055fd86f7cc5917581989e3210750ad4de27ef3baeffeac8));
data[171] = Pairing.G1Point(uint256(0x0876a5b4e78b7b0b091988875a54890d6aa96b79ea2c6ce2a644c05266e4efd3), uint256(0x0b291f3e6b731734a10562db29c119d6d34e22bc787041638150f1ba994fec50));
data[172] = Pairing.G1Point(uint256(0x1c01a4f01736b7a57dbcbb565b2c11ed6cf2b558c3b803be3746a524d58e0892), uint256(0x268e87bdacb82ec1c0e4956ed29b495860e774f46e9156b2913c37ff40c3ddba));
data[173] = Pairing.G1Point(uint256(0x18f510d9e8f3f6ed1d274859cfe02bce6dac804854cbf2a2bf65a1e3864642d6), uint256(0x2a0c240b09e0cca44f6a678af6f8d187a277764758580a0c8e5e23e65dcca02c));
data[174] = Pairing.G1Point(uint256(0x233f4a58689b61f2d1b8c8c2fa123d4b0de4147538fe5aef18aa4a30abf44f5e), uint256(0x2e3629560ac18d70ed5c3a01aadae048efef518903a381dbf69065f6deb65862));
data[175] = Pairing.G1Point(uint256(0x1f8e93cd8d1d74b8d0df058430ff7d3b818ea1d595c598c16c335efec9644011), uint256(0x01d24dca2f32682c6dd9683d8c5c34121b91d5f59a88bb3e5d6c7c321a96ea2a));
data[176] = Pairing.G1Point(uint256(0x27950f865a92e84cf2a8683fa5f506ea05a04175cc7385fd940d6d76de4cbb8f), uint256(0x250cf54531692c740e6f1db45554574ad278b39be55e1d2c1a2bd71befcaf49f));
data[177] = Pairing.G1Point(uint256(0x18e88aadeb3ff1b5f592bfde3b91dc29f79c5d368557e26e9b66337f2edefcec), uint256(0x24602ae0fdef3540439da262785ecc024348c12fc49b7562532bcec8845b6f5a));
data[178] = Pairing.G1Point(uint256(0x29b449ab0e1d07bcb312b07f8b4069a8ada83e131d996874a1d9aea8a4408675), uint256(0x1710195b2a5eafddecfd0b4be15db97d573077466ad750b8559d644410661e81));
data[179] = Pairing.G1Point(uint256(0x0d135eead49b51b37bb9f36a1fd28d6878e48783a123f4e2587db46a9f1b9e5b), uint256(0x164330cf5e99de53dc2a978d2ad8c45f8cc3dbd31b3b9df03e5b601dfa994ace));
data[180] = Pairing.G1Point(uint256(0x131de46793c439997215df61db08b1e2b88c3578f8d088e6632f4ed3795872a4), uint256(0x18b1d4272ebc96e3c24c3d7c97b91a293cc2edc6202823f35ea28ef250f3a77f));
data[181] = Pairing.G1Point(uint256(0x1c36abdc0de8f1357aa67f08995e8c8f1f8fd8c85b4f62523591a05363d728e2), uint256(0x0972b4c658c7e949c81b64bae1a34a839c6bf433a5cae90a7b77fd2d87df0c2a));
data[182] = Pairing.G1Point(uint256(0x055f9b07dc37ad3d96d2ac34f3514c5e85fcef71dd000e387eedf6002127d9ae), uint256(0x12f13e286ec440bad5d66385e67795c99cffeec18356735b94f03905dd583f5d));
data[183] = Pairing.G1Point(uint256(0x1801ec58e239c59c2af47bab6262c9558f35d20c9a4c8caa6302da6f54c8a2e8), uint256(0x0f10f3bb15020f0f87045ea0abb2e5be1d00c42347a3daf010e10288df0aed82));
data[184] = Pairing.G1Point(uint256(0x18f452cbaf22a598c510e5ca15fafcf33be8d88d69ccee1f794e60f260c8f63b), uint256(0x11940f23fff359390c2ee571671b440e3b1cfd4315a0a96038b39c49ac4c0692));
data[185] = Pairing.G1Point(uint256(0x0d8cad32e0a0bbe1c38ee6a70a3a4b7d9967ed7f9eef2acbd89ab86b73eda9c0), uint256(0x00285255abcd0ba70f332cb9291c0151a3a8a3d8763e7d21ce6eb6abb6d37c75));
data[186] = Pairing.G1Point(uint256(0x16837b4b0fe5ad64d094d123276b5a2be9cd47e16b4b5fab5be24074127e23a1), uint256(0x1cfae81f1207e1668cc5ece26b4dd7f62ef60b0831c4e6669d5239bddfdb9b5d));
data[187] = Pairing.G1Point(uint256(0x151ead329449abe40163b3a933efdec6608377a316561e60be33e5f2f9890bc8), uint256(0x28edfc3acba0bdcc32026deb9760ab240ea74c930c627290e43a30dbb11f9bba));
data[188] = Pairing.G1Point(uint256(0x23e1bd8d4ed6075bd7d4af5f7bf832c13f6591529dbd819acb5439485dc14378), uint256(0x19678285a713bb90752c9a445ef9288b5d971891200dc4e8f17ebd2d1298d90f));
data[189] = Pairing.G1Point(uint256(0x08659450557fd5ee56e3e000054324b6b1790e78924968868331c7e037f0f181), uint256(0x0500203f6ae7217e068b99b5303eafa0ca8612625d06c58323a807b336342c87));
data[190] = Pairing.G1Point(uint256(0x2dade7470d42d6e1641460625a9defcf578b3bf5c1ae67a2db016601d0a92aeb), uint256(0x1aae6c82571deb32e06cf586a50e379098f19696b150a7c08fc33cb9ee16235a));
data[191] = Pairing.G1Point(uint256(0x03c41a7293d51634b64cc4b5e6839e7eda7c37f060ecc4f1afba3e6bf70d30ff), uint256(0x16ee18168a2c077d6342d54c4b52f5e3632266ad68206d1704ef4e26e5262e2e));
data[192] = Pairing.G1Point(uint256(0x2ee6cf6b4796a9e978d8d7fcd49a890ecb050498f7bf9fe5f238ce11664ec5f6), uint256(0x29bafa6be4e364e313753e68c0e8a6d3c799f21390721aad4aac2326056d3c4b));
data[193] = Pairing.G1Point(uint256(0x2cafd901344b6d385d95decc01eccad2f33ce8d6f19ad87f03d99b68a1dee553), uint256(0x23545f451303e616165eaacd6aba65eaf88585488b1bc16540af28753e2746a2));
data[194] = Pairing.G1Point(uint256(0x0249a4bd78be7c5386ee862a605cea23777d3600a8aed94aed87c06f8afbf415), uint256(0x1e3d06f18a2a5c748098a5a105cc4336c76e0cc9cf0d42eeb26f58483d2cfbb7));
data[195] = Pairing.G1Point(uint256(0x1746aaca107de4952cacb631351bc75d47652f5e15cf6eb01656695cd1f86c84), uint256(0x0a3ba67030df016a3405787def29b3d1987cf601a6b4e8391b7932c56278137a));
data[196] = Pairing.G1Point(uint256(0x0c9bcd1429eb735785d8d9e4cea148dde7650505e401a13b79f59ea6055916e6), uint256(0x2449edfa9847165746af2c50509165004f42263e7eec3f5b8bbad0860d039010));
data[197] = Pairing.G1Point(uint256(0x24a78027eb09b6534fb5dd0f0f5f7ed7e3d27f13bb18731acc5eaeef9a867f4f), uint256(0x1dc8bec22d5ab1766bcab78815f64bc556ac5a7eb3238e7e0d8d2e2bb737145a));
data[198] = Pairing.G1Point(uint256(0x154a3c5079a54aae7a247e94beffee4b640573d0d129471fdbd355f828c1b5cb), uint256(0x00cebe2cd226902689c52aeebc9658fdac09d912b00c1653ddb0edf3af9d88ac));
data[199] = Pairing.G1Point(uint256(0x04d38626951ab93a9aacb0ec2b45e189f9ca91c65114f66789ba81c5d0c411e0), uint256(0x1df98e56ec89f276f503d44157ddad2ae91c1cdf484b7f631bc03157b8f793b3));
        Pairing.G1Point memory vk_x1 = Pairing.G1Point(m1, n1);
        for (uint i = 0; i < iinput.length; i++) {
            vk_x1 = Pairing.addition(vk_x1, Pairing.scalar_mul(data[i], uint(iinput[i])));
        }
        return (vk_x1.X,vk_x1.Y);
    }
}

pragma solidity ^0.6.1;

library GetVK600 {
    using Pairing for *;
    function getvk(uint m1, uint n1, uint32[] memory iinput) public view returns (uint x1, uint  y1) {
        Pairing.G1Point[] memory data = new Pairing.G1Point[](138);
        data[0] = Pairing.G1Point(uint256(0x2d3cc17763704cbc8cd5af11551385ef29181aa6eea14f578238b473aed5653e), uint256(0x049b9dd2f099dcf4eee84e779fe38afb084270a724630aa3131528171ab511a2));
data[1] = Pairing.G1Point(uint256(0x070008d5c129f93dee3ea33c2fbb0cc5569354f54b9017bba692b574987a4299), uint256(0x27a2fee2949212052cc28c0d60ec403b5cf55c325cb8a1dc312fde8c1e04fda5));
data[2] = Pairing.G1Point(uint256(0x1dbdf216f1012be873bc603e669c8c688f8c53eb0c9084f3c48e88a1473459af), uint256(0x29604e358120dba332b738083d67754254de9213cd5f58b02d9e528a692b63cd));
data[3] = Pairing.G1Point(uint256(0x22bd0739bc39a0c76c39f268fc6842db44089d4d2a3b83a8f9c34fcb2d48c3b3), uint256(0x22e35b6c6e95053d150ab23020805c1e80136194397e2da8c95aa7c8d520fc95));
data[4] = Pairing.G1Point(uint256(0x189a48f60e3a109e788626d0f3e5e3e3a1141bebd85747de698f030de625ac02), uint256(0x0a8de1a18125bae999aa1a80c30c201cd962102e1c2bcdb9446004b46bd27789));
data[5] = Pairing.G1Point(uint256(0x1491dd785991b1d2237214b8d5bc477b4b629476b03567ae129b1cbd4a8d7ffe), uint256(0x02d300c174ffd37b3f11f6768c207b047c1b0ea20b8c7bdda2224a6347647f98));
data[6] = Pairing.G1Point(uint256(0x23b51817bd052363547aecc0f69d53294b198fe0b8ef3215061cdddfba678b85), uint256(0x061a1ded856ef2ede8948a857e7444b48406aeee1e941d396dfab8bea3274c17));
data[7] = Pairing.G1Point(uint256(0x2287b415fa139c97f2cb8e0e2278ed37e4dc20ab061321e7d91a63250509c047), uint256(0x20958acacf216819727d8816874dcc27840cafa92ed8450c2c4f6427af80d125));
data[8] = Pairing.G1Point(uint256(0x1d9c5600a9664bbf7c0dd83169f760a77c4a4561f3e4c7627f07249707480ffc), uint256(0x1e258855f49cd97b223ca6d7bf89efda86b3111c37572c4c5e6d6cf6a96000c9));
data[9] = Pairing.G1Point(uint256(0x2b0b7ca85dd7c48308014176012dd772929355300d0638c3af4fe6026b8842c6), uint256(0x0eef6d64d3811164ac4681eea37c8119078178c2954432416352f1eb65b64c60));
data[10] = Pairing.G1Point(uint256(0x043c15633621e12fa7e008d7e3f78da462b27a2b6290cd74aec9c798adbe5c5e), uint256(0x1b483370d9b9343dc3ae374196f20e0227e2701c828067232011c5706e7f1946));
data[11] = Pairing.G1Point(uint256(0x263a15fa44555c9f812ea7be302514080081dddfa84d389cf9bddef0a42746d0), uint256(0x05df5fd10592b1fffd4eae26e3439d06edca6185168f14e496ca992002bf39e7));
data[12] = Pairing.G1Point(uint256(0x2ccd6b86c59a566cee7ceee39dc1f2019451540e30258e04bb4df13de65727ca), uint256(0x16de119a85d412897d0518d2e2a7b5e689ddd5e9c48870ca4c3f2a2cc71b49b2));
data[13] = Pairing.G1Point(uint256(0x0dd2b712b4aad42e5c2cb1206a44dd137db978565ee00d33f1104f496046392e), uint256(0x0da60730219dc21e68020e8523a58382cdf92b9b5b4083717f3dede7e0df54ca));
data[14] = Pairing.G1Point(uint256(0x157614eca9e5037ec4869be5174000baf8b4b9260b4bda9e4910695211448051), uint256(0x1e07dd949373cba62c02b0d2d3116725e7672f86ce80987d83f5173e72119871));
data[15] = Pairing.G1Point(uint256(0x10f6de6f8660fd2160ae4daba71872c9255cb001b91d25b1e00cda6992c2f805), uint256(0x1da920c7ce783e81252315f3550c3e046977d5eefc284eac48a8230b33938bd2));
data[16] = Pairing.G1Point(uint256(0x0e4bb09981c438de501c5a5a29bc5050e66471bac392d28a9386887f951f5dd2), uint256(0x283755fb58f19b063837b4e1caa9c842c0eab940d38bc0727414b37bc4d5b49a));
data[17] = Pairing.G1Point(uint256(0x248af20d3e6c579554d8667df79c93a6ea7f1fed7ffcb5497683dcb4d984317f), uint256(0x1ebf82b4d499271378a14fa807821847785f8976ff351ae3178795d98b93ca61));
data[18] = Pairing.G1Point(uint256(0x1279e15cf7754b030245c62126a02907516ecf0e160078f5b9c131c8dc2b1226), uint256(0x06a0a9f2df0db852069bbb9e91e733f20ee9a04d00fbee956fc0260b7367a1f9));
data[19] = Pairing.G1Point(uint256(0x10d510496346fddbfa0212fb90f1b0f1b39a3b7da9c3e5bb665845ad9abfc780), uint256(0x2c1ff29c87c24381fafddf5ac360b5c62f1b10e76dcb9910f4bd00de678b7fed));
data[20] = Pairing.G1Point(uint256(0x0e4e5535f15467c88e4848e800094da743d2fc95f0195263ea2f23634a4228a6), uint256(0x0e5e8567d0768d889fd7c3333055eedd369f593b950c2ad0fca62e76cb834904));
data[21] = Pairing.G1Point(uint256(0x1a43d4ad4c02fe49ff493033e84503af6352644f2c3719c33c2f792d9cbac279), uint256(0x2fc52b6f26a42dd414424f63140d4e1adfecb22c05cb1cacccb931f18b36740a));
data[22] = Pairing.G1Point(uint256(0x286af1989288ea762b92322c701658f7eb77e0b9ee3d1145faa25bd60a8af0c8), uint256(0x28968db4cf5d1f37473d7f631d849453e87423416cd6fe354197514285af47cf));
data[23] = Pairing.G1Point(uint256(0x2ad34ea81c20c534b4a50d18f5f84b2d4e027dcbee918047542bedb1d26c4164), uint256(0x2e7985e32378c78166e7d148e496572ff5baf998848d8978e0c7e49ad3b2d688));
data[24] = Pairing.G1Point(uint256(0x0d0b4c86a193f214a8d390bfd91804d3f148dae5889f326e652c3ec066cec6e4), uint256(0x1e60427f0fb258c71469e753724fc46f1ab9d2a2e177ac372f8a4bcdb763f329));
data[25] = Pairing.G1Point(uint256(0x060c7f9465c8e348bad8c57334c3cd34a8019a07d7329d7cb49de4ec351b9d71), uint256(0x17581d378023ca2adfbe42c5ce2646b8a0e828640a091124b2b2b0d380dc4922));
data[26] = Pairing.G1Point(uint256(0x072822d7f2b4c34e03b1741e0b17d4855b9657e34d793b457eb49dffeba24dfb), uint256(0x090756799e7f8a8c01f4fcc944870e68b0f045577f0deb5ca642a05abc8b4b06));
data[27] = Pairing.G1Point(uint256(0x0defbf4cb7eba2c2bf62006e20c14f2ce159f5a54081400066c377549cb5855f), uint256(0x0242d8b9cb864f7723b0b446ae28de9e6d9e698a41802b7841eb9e3c980a50c7));
data[28] = Pairing.G1Point(uint256(0x19621b77cf3fe3ce12b8ed763b54f7f62cb09cb25f1bce8e8ea151cb97aac668), uint256(0x2f6b9d2b7b93c230a4ed25e67cc48cd84d8c45faf886b4a2b43bc4edf2e85fd3));
data[29] = Pairing.G1Point(uint256(0x17353aefb629ebe5db8d5ec0faa78f207517a70d9fa12f0bd9bb457225dabc1e), uint256(0x27d3970327a4146cf960cdbcb956be0bc09d1c73103c1a89665b493ba9bee9d5));
data[30] = Pairing.G1Point(uint256(0x22fda6ce2173473699f65c0187b1f8a61ae9e42e3786a764c5e82a9ec42eb4cc), uint256(0x15dfacebb60f5cd2826ccb274705fc02e6395cbf075858382d694ff5762e9b18));
data[31] = Pairing.G1Point(uint256(0x0594b3679815e0ee1503a0e2d4f418b5fb7cae32780225b2243684e8f0cb9b5d), uint256(0x1565b522b48bc93122498632a0f71dab0b1d3ede3f36a3c483c6162215a87913));
data[32] = Pairing.G1Point(uint256(0x145d61a8a6a4dc3541ad77e82b8357ba28fbc016f7a6f3693ef331401d0df0fa), uint256(0x147246a52ae81b7724ac6e41ec5a4be69364e253b618a0002e7f055e2a1a4f00));
data[33] = Pairing.G1Point(uint256(0x2f476826338c188536294bd753cd1391734028c1bb0a3781870ea8d118c1ebf4), uint256(0x01eb2478a20f466e63c068b39fb5d6e540cd5a17e9683329c47434dbaded87c4));
data[34] = Pairing.G1Point(uint256(0x280908fdca93131f31cc6c78c707154bc8ebc8f03bdf9322d4da78235dc8f167), uint256(0x01245dd9f445ea59dbcab1e2693652fbcc6cd1aa796557ac8b5ccab7ce382004));
data[35] = Pairing.G1Point(uint256(0x01efc5b65381d1bc7e628aec4d02f006e09441a8fdcdd15f6a0445f59c8eac87), uint256(0x01a573410b93fef17f681f68a881c47d4f41a8d40425177ad2ade1ad5c603988));
data[36] = Pairing.G1Point(uint256(0x0cd90e804563ebc31450fb57f361ba31d26e28dea897b1b09a5ab33c254494d4), uint256(0x26586268b54adbddf7a9a4da1522eae308cfe887174df6e08fe834704eeb7314));
data[37] = Pairing.G1Point(uint256(0x27650b66253f42131911712ac25b56b3ebefcb554832e8d872a462786dcf2b96), uint256(0x10ccbf6f36a815bd0731075cb6f71886ab63549d300208367ec54ebcbe8597ce));
data[38] = Pairing.G1Point(uint256(0x1ec7e550fbb86ce02ddffbe837485abedc8f2c780089a00dd481ded14be55df1), uint256(0x2ebcde40639d7cea78261f816180d3ad9089a396274cfcf721301a49542163ba));
data[39] = Pairing.G1Point(uint256(0x294b9ed53a5b1e742ff15e7fdbc40c6bae48f4b19f9339088abaf546e8059b10), uint256(0x151e8ec0157669c800c3988ee6eaea10924f9746a1a816d9adcd6b988c262112));
data[40] = Pairing.G1Point(uint256(0x2e5340d482183bb0830ca4917a96f0eb018c936d1d1c94ee87015e8bb2ccc089), uint256(0x263663945b3a16cf4c70cc8cc4b47579748ed2d4f392d25b4946aee33e9e265e));
data[41] = Pairing.G1Point(uint256(0x0668f2d3168a94d3d3561ccbae1f429be91881904a553922158a9e289c7fb78c), uint256(0x094f183eed7535865a31b9aed9cf0357dfd4d1319297cd50ac72911d7132fe3b));
data[42] = Pairing.G1Point(uint256(0x0d878654dd2c14f01115b51529b7730157b2412b6a8d8389862c1164c30f9d39), uint256(0x242821a67d8a1846ba4ad6e01c1f95c51077436254ca62b48cf0bf4b25817e9c));
data[43] = Pairing.G1Point(uint256(0x248f852c9c59afbfd6719a0ab595c0e4b0d0bf4d9d97a2ac7cb242c6aaefb3d6), uint256(0x0a5b07ab8769ed013ac378ad86a2763efb42463d46aed281422d6f5ed29aa29f));
data[44] = Pairing.G1Point(uint256(0x2d6fadbf3ee88d5fb73b1c3847451bd6c96b1cbacd1c3db28dffa32ba1844b2b), uint256(0x08a3e93d94e350f3f68e33be1d0a10bab9766c95322307593a88c6008b8920a4));
data[45] = Pairing.G1Point(uint256(0x1782b8e5195ef66182e57ba5d67ca4b2d82ef69cf95a6cfe8f685097360dab45), uint256(0x0d9c69c227298fb9fef431caebeae59961258eb4d62a4d415b50d87376ab3b71));
data[46] = Pairing.G1Point(uint256(0x1168312cf79dd89eb54a93a54f88d98ba33d8689cfeb51443f452c21b60255af), uint256(0x174c74414e52d1ca607ab32c8d75df8d4e313b17e4a04bbb9d0520ce28b4682e));
data[47] = Pairing.G1Point(uint256(0x25f836d22854b980d0d0c6320d8f5a30bd7d8d265f8b239e504bcfa114b9e9b4), uint256(0x1ccd65eb12c6a4d8ac83eedf438084143ed08536f2f7385eb46f341db02ff9c6));
data[48] = Pairing.G1Point(uint256(0x1b03d233ff2db5af59dee2df717494a4500893426680ec476e1f3d21e199cfe0), uint256(0x2671ccb1ea3b2d23cee8cedd7dbf4febb8815240c1a3b9e16f92e4b66d442c00));
data[49] = Pairing.G1Point(uint256(0x07fd99ea3ea1e3b9e6dca49e63cba3b24a93da95bb28b7a60c608356a16d307c), uint256(0x080ea907bfdd354ae44e1696f91e50a795bee4ae644edf9174396d96a2b8a935));
data[50] = Pairing.G1Point(uint256(0x26c0648c7964d4a845eabac435f22418d4c6247a98460036063b50cedc45cfeb), uint256(0x25ae12dbde6d95f142308b25d17641bd0d8f8f06f03b521b01b566ee946d9313));
data[51] = Pairing.G1Point(uint256(0x14d174b6d85a8d42900fb03d9c234a41f5ede57077f4eb5b721ce3a9dd885ec9), uint256(0x0891ba8d825248a330a45fd29cf21a515dd72edcca693c7a9ccff3370d6cbc3d));
data[52] = Pairing.G1Point(uint256(0x1584f918bddca1eff2b71f028ff8741c849215bee9fd85cf996a365af12f1b59), uint256(0x0da184611b502e3a69da05d5c0c99a975a614428651f903925334e8af5d5c777));
data[53] = Pairing.G1Point(uint256(0x2d6a03c74e5ad9ecc441e1c0848c34ce105c1b9a0643b55d7247aa5302edc29a), uint256(0x1568f4c277b5b019df7c77b02578985cdf375609970cb91205cb247ff86e1eed));
data[54] = Pairing.G1Point(uint256(0x21b3758de44fd95d05f5b38244449d37379ab4ead2fb938bebe31fd07bb54754), uint256(0x077a934232676a938b25200289828d28ff968ea4f834d64fccab30fb4e58bee8));
data[55] = Pairing.G1Point(uint256(0x208270f25bd9e67c04082857d4b7c8a50167ed0a1e785a632f2ad87b088ec1e3), uint256(0x1aeba82e11ad700f1d093c0012d8d77256b72d399cbd461bf6d9d2b3eea77a13));
data[56] = Pairing.G1Point(uint256(0x0f594b413a226e6cc502856efc702294faf5767de3dc629f2e5de323e4ef5d1b), uint256(0x28e41a3167ae276647b3cf5b296751ddc80dd4a5039a6b197bfc1bba58ddec6c));
data[57] = Pairing.G1Point(uint256(0x00d0a4ba31823220fa289eff360ec949dd09fe5b9e80c40de49056eac0645cc4), uint256(0x2056f9bc90eec39efc64581f3a5e0c062650eb172ef40dde60cb7fe7d309a24c));
data[58] = Pairing.G1Point(uint256(0x2eba2f0ed46655653a5f966bd4429acd973e0c9ef6a61ad2847145270b7cb3a5), uint256(0x1f660bd2b18cf33fd6ca4b50245b9e5e5498b008c4a15581779a4d1d38285ba7));
data[59] = Pairing.G1Point(uint256(0x1700e289f74acba2198619442862c09bf18ca79bf53b673f70a019caacdb4a63), uint256(0x24bee7e6a74402c644c61c8f6c14c23ee0ed4414ec562942f4b2aa586effdbe6));
data[60] = Pairing.G1Point(uint256(0x1354ed6189998dab0f75c9074856c3bb4c51db47fef8c1d47b6b61803c0202d4), uint256(0x016af77e48f4e33c6f2768ec19e1720392ce027abfadd295261f0bcee6387a0c));
data[61] = Pairing.G1Point(uint256(0x0c939f2b9d432f3f1689a71f31759cf55e08d558d472ce2ec290d97058260a40), uint256(0x2bf4523602581f810ea2ec154f8f7b3f6f470f08daf4891a073f02c8cfe666f2));
data[62] = Pairing.G1Point(uint256(0x25cf379d31d4ee6c87bc6af98ab5bde92283de93297b66752a518a2e2509aed8), uint256(0x097bcb21ea63c370f7bdbc338f78203f85d7e11cbc3151c0c270072f29fb25ca));
data[63] = Pairing.G1Point(uint256(0x21c6e08077fd9ea28badeb35e3ea13b47fa9fc1fe39ac0541af6dd4fcaeefc85), uint256(0x0039024cb7841405df1453afc4bedfcece2bfeafec5d491854b31edcc23f35b1));
data[64] = Pairing.G1Point(uint256(0x1e453a3211e1c0704bd1a8ccbf8f0d1d4b6b6c279b95196356065b2559254c34), uint256(0x07276a105040fd813a0f79ec957d3f0dc0e852f67970ade2f63766af101d5b82));
data[65] = Pairing.G1Point(uint256(0x0831d40f3f99c1b5a020410d3ae9a4a3753cbaef7689b4847e5dd28b7de8102d), uint256(0x0dc1a24156bfcb43a5622e649fbe4feb499fc7f5b47e3ad4612c64b9c02fe598));
data[66] = Pairing.G1Point(uint256(0x2445b0edd194d3b847b95882319cc20781327017587d642863971ba8ec0a7f07), uint256(0x17c0c0ca0758852412ab4c72867216f89fd0e8b4b4bab8ab337a049dfd2f24a9));
data[67] = Pairing.G1Point(uint256(0x29675a90cac5499e3fac2c85a1010e1d76ed328e57061e488e25c61adc71024b), uint256(0x2f1e3124887a3227b7c552c625b57133f90f94039f7db183326c6a6a14344fbb));
data[68] = Pairing.G1Point(uint256(0x259ea53cb34b8b4f46670d31a1d1756d9fb83e910ac05956104c4cf1c3878f1e), uint256(0x1d0632096fafdd64c1f6f9b73d22840df1a94a4fcf886c1a4370f13f6156179a));
data[69] = Pairing.G1Point(uint256(0x164a2e92408ac6c598109a9d52ac2f92e0114fee59224643e1c0e083a870461b), uint256(0x2057ef21036998b3f58cbfecf7db9fcb98f0df7176e65d8280a45b632d7fa471));
data[70] = Pairing.G1Point(uint256(0x2b379540f06dcec088ba2373fa385a79d14f84bac4d31778ebeace0e68610eaa), uint256(0x1c1c1051f7bead6fd2f43426a8c8585d7eeda6e8c360cfedb937ed4e1cc0b56a));
data[71] = Pairing.G1Point(uint256(0x1ebf98a18598f6813339ee0481c8aed100805ebe872542a15d8eb9f2472a106d), uint256(0x21b8550ba7bcc8d003c489af1884d7672cdeef8aaaecb9219864f41ca1be419c));
data[72] = Pairing.G1Point(uint256(0x28112abc22ac13f2db6392db936d127fb5ce3be6ae86a849c3cf6f533ff551a8), uint256(0x207a1b4a802a31ab4be5d5f66fb47a05b2c35f823e0888f0a14fc8e8b449d31f));
data[73] = Pairing.G1Point(uint256(0x02f4aea8749217106d2f1fc821417735360c83a9e7c6456cf568f6b4e282f36a), uint256(0x1ab4c667859879bec49e3cde0fec138b8cd12db339ebe0e07f097c841776a7f2));
data[74] = Pairing.G1Point(uint256(0x0f3a6692782276777a3a196a49f31dc22b402cbe82f6756a550b10dc3e9ff431), uint256(0x1d39c5bad65998b811f9f0b78c453cc8521578cee2772c77f86934966eb7abec));
data[75] = Pairing.G1Point(uint256(0x27cde6c0d018b1e5e646fdcc7b9b1488f19cb213383996a518e2e2f4a875a6d5), uint256(0x07834a6cee8170f5a1cdc859a9f64eeec5a444b14208d41749a0c348b43c8c81));
data[76] = Pairing.G1Point(uint256(0x207b946b10d2d311152048f41e499ae9f45cf934eff8c6646efc54d7a9b646ac), uint256(0x1442b3572b47aaca288dcabe7a26ff52d7e4e51bd1e7095fe09b6be03e954339));
data[77] = Pairing.G1Point(uint256(0x091128964eb43ec06cc704045cea7afcc18cb36497a201393b3bf789a6aee97f), uint256(0x21f70cd79156b64d3fc197faab411aa944b76512d70907a3114466cc9c00e592));
data[78] = Pairing.G1Point(uint256(0x19190162d06f53ae7780ec8fa5edfccf6c7da0994f3e6ec125924d1b3ee0f110), uint256(0x1f5a7cfadceb664c5bb75a580463c27ed09fbcc3aba48d65b856e68b82531457));
data[79] = Pairing.G1Point(uint256(0x1f7adfc74444757a8c63d68faa4208e8176e35f8bcd24feb2a67b104093c291b), uint256(0x2aca90b101ae7480dd09ecdcff3c0ab9e6e91ac8028e303d18485d34243a1dc7));
data[80] = Pairing.G1Point(uint256(0x2fabce26014c8fcb45aba40bf58dc6d6d07dcf7a18166710c1534db573b25dc4), uint256(0x16f016fe353f1d1cb187b385570409c7bf945e699922a043574283e77fbbac30));
data[81] = Pairing.G1Point(uint256(0x0287c5594a30099b1c5b2504e25a9c6cd590b1cf83dc7061c8a4e1baa776519b), uint256(0x1b3236be7f9debd37acec50b2e50658ffafe5a48eea4cc640bc35e047a7015da));
data[82] = Pairing.G1Point(uint256(0x04318864d106a27efa632d403267cbd15c3400988bedf234f66a0bb012ef4c83), uint256(0x234ecac8ee770fdfeaf9182fc2b873de891e0582e265c8c1ad3bb0df55c9b64c));
data[83] = Pairing.G1Point(uint256(0x1db5b395760066a73e5560b2383579405583e695137d25c89fd136c8c05236f6), uint256(0x0f2bcd9a2b1226a2ee1e9b7b87af8568710f15a6842ffefa888b3b1a61ba9576));
data[84] = Pairing.G1Point(uint256(0x0f715a7552accf1e34c8c16bf7dba670838895a43964585e7cfb70ac7044cee3), uint256(0x2436dd741df5e9b7f740d49cc2af620ef8a663082deb7a8437d294ec4b84f34f));
data[85] = Pairing.G1Point(uint256(0x2098c029a623b26e385aa92f63b8ebd1d2860a7922cb27d6968aeccd12a874d8), uint256(0x2e56dd31eb6e65dbce6de0944fa04e328c7d52b5c3ece97142871a56bfa3276d));
data[86] = Pairing.G1Point(uint256(0x210cde0989e674cfaea979d8e178cb46e1c8d65b8f91cfab1286f71419f6eca1), uint256(0x17111c243bfdc346071ea62e055b2d1288d084b016843ddfb3806e8ea2d27926));
data[87] = Pairing.G1Point(uint256(0x237826c1810e816cbe8a48ed4042c45ca71da2e767e69f8f689e14c5dad354f3), uint256(0x20ac2bfae708a6ee0ab2153e9b073017d777856adf43f9b714022b587b7c665f));
data[88] = Pairing.G1Point(uint256(0x24cc29623daaa7a5f32971dfa871bc99cd7558f6a5901457ad3dae5e83a24590), uint256(0x07d024bfec578c9b78addacc454d06371a9fce313dd67954fe855e7b14d0b512));
data[89] = Pairing.G1Point(uint256(0x0dfe29e6662aa876ed9edbe60a744d1897eb89db475429086b14eb681a6c5952), uint256(0x1c0206584056a876e27c7efff534e5df0d1b0fcac8c6eccdf0b64e0a298bb9b1));
data[90] = Pairing.G1Point(uint256(0x01e484f35361f2a6f33e1e061c00984984f79e5e3c12a8fbe564cf54dad31f01), uint256(0x129daffa416a91d6ab7347a3138262650e4c01e7b36e97131a0c6c6b503cbf57));
data[91] = Pairing.G1Point(uint256(0x0ab2964ce63e837e2823f03b174e8c8b51f410dc2014a2e66990a4a88361cb07), uint256(0x02536ae4a8918ab97b99c2ccef3dc17652c535d9e705842378e6bda6913b78c8));
data[92] = Pairing.G1Point(uint256(0x2a7fd21c224b919ee6985bd47ef046814fee90af8123b6bdd7cc957c6e22ee90), uint256(0x162807f32c17fac5ee41645698f36d6e08f987f86aa8c54b054f268a38d61efd));
data[93] = Pairing.G1Point(uint256(0x162e21ffcf35d1fa078b143d576a4fef901f6113810e76172df2b995903dccc7), uint256(0x2ba0ee4a3a7a2f5c10781a30dc35474248b984724124ec49fa46dc06f4bee8ea));
data[94] = Pairing.G1Point(uint256(0x29db83ca0c1f2406e4b5096f43f07b363251b985bf796cb4f60d222870cf6360), uint256(0x23a5213992f99da7e1328f334c72df9772ba40496ac06270a8a0f3cc1fca941f));
data[95] = Pairing.G1Point(uint256(0x02feaf3251bb96e3604893f448a3efa5148d637747914b8297ac4afa48ffbe16), uint256(0x288f748577666a9e88d010599545af497ea2b2bc731424af5de2a9205b76bf7d));
data[96] = Pairing.G1Point(uint256(0x290f599871efd4269053615138c9a1bef318c884b466e31bfb5e8d3cb1eaa112), uint256(0x114409e08a80e0753c55dc00b15db7a9009b8fd9465fe33d17b0863248696ada));
data[97] = Pairing.G1Point(uint256(0x1bd6be78d05cbdd52b8dd375eb88af30914a9ed437e01f11c3a351a64bbe89a0), uint256(0x2f2e0fb466d95ead41b4178cecc0fe494e2329eda6b7877ec3cf061e623341cd));
data[98] = Pairing.G1Point(uint256(0x027c744efe30feeb24b6293487d885986dfff416e57f2c8417a1a62ac77958af), uint256(0x163f97cc258a1b6e533a0027f2106a7b9dbdbfd59cf8a3a87f97d1c5eb2d534f));
data[99] = Pairing.G1Point(uint256(0x0355eff7e9dcaba32e5549f988f14506993d9125e3dae136d9f6c56637d5d892), uint256(0x244358186e0c4047d187f28c7faa93d3008eeacf35413046bf8bd4d78ee017a8));
data[100] = Pairing.G1Point(uint256(0x0190e9d388b2d31db80f8211ad9c1fcba0382193e2429ffaf74e6843cd0e432b), uint256(0x265a11bedd89c836a3d93cee4ab4e398690550f64673b09c224f45c22146beb7));
data[101] = Pairing.G1Point(uint256(0x059cdd246a05f897057c13ba40a6dfa892fa8bf061bfb616d70771e0464eaa79), uint256(0x09970315c1918b375fed19b8d1f8afcb5cbc00e66de6b52b0f080d346261021b));
data[102] = Pairing.G1Point(uint256(0x2a97b83e0b5d2dd0e933ff04c6ee7b43bfea9c34f03b3b2a29b36c87205262a8), uint256(0x0e71e5f75464a4c237deda9a67971db7a6c97abf235b6ed16b2fce1772080564));
data[103] = Pairing.G1Point(uint256(0x2cc900b05f34113511e97b578a350d84a81c6765ab30432ba9070f1c5934b829), uint256(0x2dbf36a28e52cc9181c0596b401ed566b5fc3e6ffd588f39466552ad4025db66));
data[104] = Pairing.G1Point(uint256(0x2259620c369789ed0e8f2f184da28e5192f7e0f0db838a0af28555da3bec0d8a), uint256(0x10bd517e31b4cd5e563bc81a497b1c7e820216bf1b9e4d7b8b3ac5132397aac5));
data[105] = Pairing.G1Point(uint256(0x2ee403daa607b4c9fbce98072a4080747ac54e60cdf36a1fe75e79db27c1e5e2), uint256(0x16687f09af48d2c0c1b033bb25051bf816877cbfe2b032ca97c983cc5379aa5f));
data[106] = Pairing.G1Point(uint256(0x009b6dee025583e880e653c3bc4fd6fad578121fed5bae33089e86710544cbd3), uint256(0x0a9b3cf98e43ea904e7a1bf96a2ec698a7c69655ae6d150b5c06a40e5cc3daed));
data[107] = Pairing.G1Point(uint256(0x1cce75f5402a270efee887e75f51e134b9309c90b5dd5dde675b896ab68558be), uint256(0x2555d043241d4049da15ea5f1a2ade144c26da5eef87ce9eeb147c6afa00b3f1));
data[108] = Pairing.G1Point(uint256(0x24e9d651667f15815be9a884c49079cf38a92e2068febbff4e80386a84dedb76), uint256(0x2e05dc30ec5679d1e388d53c9d190dfc0ccfbf4f6d22b6df6095a258e151b3c6));
data[109] = Pairing.G1Point(uint256(0x22d0464e3071a8c8b3c5a2d5267006ba5ba790bed7be0f3d37f77e3b4b5e668b), uint256(0x016573083b4de10599253d36073945884a592115abc5dbf4cf47359d819631cd));
data[110] = Pairing.G1Point(uint256(0x2da902a34c653c4ab9c9a8054f7f6875d35d604994f3dcff41694a822b154c88), uint256(0x0a43d2487c0d2950a38580f096fc2fb1bd582347f533db3e6a8c69fc52d61f85));
data[111] = Pairing.G1Point(uint256(0x1d6d8e7b7d51928c3fc41e68a697d5a924f6004438ec94c62d4bc67e78dca43a), uint256(0x0645cf64f8a7791a208ee3d980f6f48cd43a591dcfa6c92133b6bab542f41274));
data[112] = Pairing.G1Point(uint256(0x144522c87e81e6c89f52f29ebfa22f58b8740db1a9a7f0ffd9d64f68fa5fb8a2), uint256(0x186b1cfb74d7ef7b4ad7e9adc9e86d52a59be5e244b439a0468523278efd21cd));
data[113] = Pairing.G1Point(uint256(0x0c8c215559cc9fa4579efb4fd5b0c6f1aa940d2acea43718940bdaf6250cd764), uint256(0x036d67916ff86cec20297e7e04524485368914393e4cbeca0857447f5d32824c));
data[114] = Pairing.G1Point(uint256(0x06a72124677219499d9981323c039edb32cbc03374944453053f0b8fd9f9bda0), uint256(0x289bf00da5849851b08586b5a452af7bd2bdace25d1071eca6536fc2c097dd08));
data[115] = Pairing.G1Point(uint256(0x067cc075de0e9848ca5ac6980c5a3a5c884edcaafc89c9b0f647d19438625107), uint256(0x2e3b22c7584ae33a89108d49e1628d2068997d11f674aecf809f4765242c2d54));
data[116] = Pairing.G1Point(uint256(0x01846d57cf0844d56f9031508e79dc80579a1472f4ec6b64bc7eede2bd080477), uint256(0x1da1e69046554a4a4c7f4055b1f8985d64e3fcd21393656d6168731b915a8895));
data[117] = Pairing.G1Point(uint256(0x028d94daa8ecbd31cc885b9eaab7e33192d26227209979211373b5bade9bb482), uint256(0x0028bb9e3346e521772a1342b9c366e5415105a1041e0a267c2191458fd69ce5));
data[118] = Pairing.G1Point(uint256(0x12daefa06b298be4786caaff6e1392ebc9e3f7c3567d3821e70af304ae9f0019), uint256(0x1de421d9ebcc3082274843c704a2dce8b8dbee0adbc3796a8c5a29b6448c92a0));
data[119] = Pairing.G1Point(uint256(0x03fffda8b630256858ae7d232420a7f9694c5674cd9f159101c98c542feed4d9), uint256(0x257b6687536159de4b1e059135599dc404b50f2d81ef5a7fb7a590a79e14172a));
data[120] = Pairing.G1Point(uint256(0x1af6843f569a5f313b5fcb7bbed0b90be9bf7a2e2eee90eafd4d50925e2e90f9), uint256(0x1d5acd1e383c65d04f5009610d8d7782e1c185a0cfc42de569995b04a49e7907));
data[121] = Pairing.G1Point(uint256(0x03dd64e580419999d2b27c0de41b0897bce7b4276706a94c59ff0899024a6457), uint256(0x1a2b7106245b3f34dfcccef893c714ac49b9b6d6df822f086bde5769be4ac9ae));
data[122] = Pairing.G1Point(uint256(0x19907054f5c7ee983e9b892f205d7be4df4112c38a2cac6dc361a9eeb2ca5397), uint256(0x043acb09245df4352ec3f2f1284f68d50ec638cc58573328ac97b3e7bf63f77a));
data[123] = Pairing.G1Point(uint256(0x2502295fca28d0639be0086465a4488c5df1bf74a509ba1318bdf8c6c8dd4a8b), uint256(0x11e679d02c9c4c0a0bee25dad1e2dc90bdca4df94796992bd258f3c459329336));
data[124] = Pairing.G1Point(uint256(0x0913d9daf2c88ae46a017d85be5231ce570efe07f94159f73eee1747b44bac71), uint256(0x13dedb81831c3ab386a52e9facb8129f1e14ddba819f9e66f6339b0ea4ba99da));
data[125] = Pairing.G1Point(uint256(0x038b68c2d30c6730781f5530b2077d26a467d8829b0d29848689b7c9387bfc39), uint256(0x277c7d2eb40b9cb8eb5c765fed530fdfad76b1da60570ad49c4e948a38942a29));
data[126] = Pairing.G1Point(uint256(0x0cc441a945d428cd7d1c72276e269d5c28ed7a54be0446b1bf728a05a6149ca6), uint256(0x1ddca1854372632c72261a5877bdd983c28676e231392e8db9123559b5acc6ca));
data[127] = Pairing.G1Point(uint256(0x04082c3795bee67d4265daf172f3231a7c4d1fb1445f785db25e546bd875fcf8), uint256(0x00b2fe540774bae359395871ec641d41ddfc7bd853f684fbf8b7d7b6fab52be9));
data[128] = Pairing.G1Point(uint256(0x08d7c0f28809ad8eae6495a525ddbf71ca1ef317f4cd99ce25e7c56737904c49), uint256(0x298d0995eb41517cadbb4b61cb1bdb278358b82225d75ec63f809edd333ef674));
data[129] = Pairing.G1Point(uint256(0x0807369bb89817f0aecb00598e49e05195712263d1eae848c07988fdabbe88ba), uint256(0x29b1d261f745e6a787ed08b16b1bc3b97827a0d6e48d25e9e4d427dd7056c4f4));
data[130] = Pairing.G1Point(uint256(0x0037567a38c228d86090e9b0e1f1f2651fbfb3250c0cdb367a1e94fd92d9e371), uint256(0x0b1ffc21a23d0eca34d684efd8c1d2cd0d64461157f82104bc598717676f9fad));
data[131] = Pairing.G1Point(uint256(0x2dc65e19dd76d9d0e0919cfe44296d7ce2f11d578812698d5431e8877d67d445), uint256(0x099c302f9f384405a1bc4b3316099cc603024f1126f48aa7f72b37c2480f47f9));
data[132] = Pairing.G1Point(uint256(0x208195574ad8a77510dfe36306220177a85a838725c391f7f4b5d6591d9a1a1b), uint256(0x18815d17dfb22f175339323cbf59249cd44c2f7b2c35a01ebb11b40a9b04bd16));
data[133] = Pairing.G1Point(uint256(0x0ebcc86d3dba676ac6234474b942a61e9b32c0c5662d2fbddfa9c9e4722ec392), uint256(0x1f8c84684052940427d00e5e49361cb6596d13307d13cb61e92cbcf5a31f77e8));
data[134] = Pairing.G1Point(uint256(0x29826e07d247388d32f7e72bc032041570b8d61c186f9846e46af816821186d4), uint256(0x1e684a691f8f2ed399f942af127afaa7b54db8fa9e50c738327e261d66e94570));
data[135] = Pairing.G1Point(uint256(0x22827947b7384634641d61664c403148353f028fa7ef7784d203720f4efb948e), uint256(0x1740793b98707f780d045d172a03b6c36e459e947ad524e56034271ee1770cfa));
data[136] = Pairing.G1Point(uint256(0x15b29620fe33b0951258eed9c9fc6b1cb28ebd65f95d15cc18d55b982c7fbb7e), uint256(0x2df229d17ea3e837a4a173e68655763feaa3f3376be3efb3e0e832a76fe186fb));
data[137] = Pairing.G1Point(uint256(0x2fe6eda89d88a1ca0b9797c43814841edf29f1793dcd8bae9d5f6da52f7b1668), uint256(0x013e70b3eec9b2ab29809f833220b03029767bb037582a5ee4d3b5dafd7469f4));
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
       vk.alpha = Pairing.G1Point(uint256(0x1e2aa8d9f7604462d803bc58b1a5740f50ed6da462cb83c53473140073800151), uint256(0x2d6086220a0ca1318db27a39c5e71780529751259c2924844d0f77a8fc34a3b2));
vk.beta = Pairing.G2Point([uint256(0x2a0e6a88dd8f76a84c2ff01d8bcdc8fda08a6e19fcb603ee131dc3eca6ca9230), uint256(0x1e78e369751e4bfac23026c4764104ca1c08213d82b6ea4b35cb1b3ddee28a65)], [uint256(0x2a0f9d2eb46ed091eaf89a08c3687197b2bc3b4b9e69dca840defcfe54d08eb4), uint256(0x01d29eaed6f5c0c5cf3357e9facc965d4cb5302c8b267189dc91e2b1ffc87f47)]);
vk.gamma = Pairing.G2Point([uint256(0x1838b09155a41d31c334fe5b39afe5ba2413aa91924369ff9425ad1f74cff9ec), uint256(0x0dc3e52792cf312294b2b0bcf5557ff6912a5516f5918669093e3268c92316f2)], [uint256(0x0a5afce4c2ca594914db5d547f2515429052ad12208d372a4bdef0f21fe91e39), uint256(0x26e6dcfe4f9346bac5758cfeb63632da335043a995e9339d25f2bde81900599c)]);
vk.delta = Pairing.G2Point([uint256(0x269e9e5859ad5755a7cc465a52c893078d5c3376acbf0b8d26c444a276bd36b4), uint256(0x0ea3302a2887a9d31a280b50c1c2178b4599f4aa4eabeb56a9a1bc3832c5949e)], [uint256(0x29c8a6e17edfab9257d1b03e15ef3bae4c28505dabc7eea18453d3aba7bf33f2), uint256(0x012ef40fe0d5a718b5c6c762dca2b0bf2ff1f8a03c8e90a45bf063f67f97f3ca)]);
vk.gamma_abc0 = Pairing.G1Point(uint256(0x1659999648f0389e2472840954bb423afd59612437e9c0c82ce24b9a3da90917), uint256(0x2cd225d744e6c16371b1a28959496bef3dc468ab3742cac581ba92d2a8e28a94));
    }
    
    function verify(uint32[] memory input1,uint32[] memory input2,uint32[] memory input3, Proof memory proof) internal view returns (uint) {
        //uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        uint x;
        uint y;
        (x, y) = GetVK200.getvk(vk_x.X, vk_x.Y,input1);
        vk_x = Pairing.G1Point(uint256(x), uint256(y));
	(x, y) = GetVK400.getvk(vk_x.X, vk_x.Y,input2);
        vk_x = Pairing.G1Point(uint256(x), uint256(y));
        (x, y) = GetVK600.getvk(vk_x.X, vk_x.Y,input3);
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
            uint[2] memory c, uint32[538] memory input
        ) public returns (bool r) {
        Proof memory proof;
        proof.a = Pairing.G1Point(a[0], a[1]);
        proof.b = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.c = Pairing.G1Point(c[0], c[1]);
        uint32[] memory inputValues1 = new uint32[](200);
	uint32[] memory inputValues2 = new uint32[](200);
	uint32[] memory inputValues3 = new uint32[](138);
      
        for(uint i = 0; i < 200; i++){
            inputValues1[i] = input[i];
	    inputValues2[i] = input[i+200];
        }
	for(uint i = 0; i < 138; i++){
            inputValues3[i] = input[i+400];
        }
        
        if (verify(inputValues1,inputValues2,inputValues3,proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}


