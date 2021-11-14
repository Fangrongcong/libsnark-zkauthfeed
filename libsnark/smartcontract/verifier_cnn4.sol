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
        Pairing.G1Point[] memory data = new Pairing.G1Point[](46);
        data[0] = Pairing.G1Point(uint256(0x2a72b235c727cffdc28172f4bb1af6cb042fa417bf2ca2659f8809e600ee1abf), uint256(0x22452e6c742e163d16bb9d469b4edfd49367122c46ec9846aee043e1b6db8c82));
	data[1] = Pairing.G1Point(uint256(0x2335206121ca1384bd2261e84849870449a9e603c606d7cc396ba1e1259cae34), uint256(0x25f3d0b07904705bb4fac01bad629ef14b82ea81ccaaa3285bbf404597e8ea76));
	data[2] = Pairing.G1Point(uint256(0x2bf5a871c1d54628ba02a1b90261dc14c920dad9846bdfd43e91acef29e97a2d), uint256(0x1524caa2d1d24eca458fa71d2e33617831e52f8d9b492497a4684da1451663ce));
	data[3] = Pairing.G1Point(uint256(0x2da7bb3bc50e84234b07a58d20c58d1376627be29102e3b212ab3c89883faa5d), uint256(0x25ff2640b8e6dab83b51522226b2ebc423f20f765cf6f507e421ae9fcb6e7edc));
	data[4] = Pairing.G1Point(uint256(0x2c782c6129d72ece81a84ac8e46c1d1195b2474c4695f38749a57b7aa76e8026), uint256(0x04abf85f0f5c4c033c3053ef49ce991020c6a5e3f14700150977c213a656b712));
	data[5] = Pairing.G1Point(uint256(0x2e1846bd5ccac1c570ccb4d086919ee43ad81e7dc5d657ad3c841b4dfa36f986), uint256(0x0abc0ac5a2d339138164626a02746eeef6bccfb6a758c3907f016a99f606660c));
	data[6] = Pairing.G1Point(uint256(0x236f0fdc1f03e9ae9bc9cab858d58ab3bef8f6550f4eaffa08dfcb246d3b34e1), uint256(0x1b85a9e1ac790011979668ce76101c538a75ee84fcf899e39a001b4df826b4e6));
	data[7] = Pairing.G1Point(uint256(0x27caf33961aba322bccad118da1eeb8bfa9a29e5e0df3ea0045a2eb6fa1ba6e0), uint256(0x2430862c3503d8878d1f70eb1718db47cf93f1a6fb6d19fc35ea387165cb9406));
	data[8] = Pairing.G1Point(uint256(0x283309122566d6508d71134aa03e17c1655575e099f7ade6467d1a2e38ea5ff3), uint256(0x0e66e7f84b69fae5a7fa70318c9de612e43eb7a2c25747b05640f10a799752f1));
	data[9] = Pairing.G1Point(uint256(0x210cc74c86f3ef230fcb3d60f8991523ada8942b384431c9b0f8880ca95acacc), uint256(0x1ff30d37716d7c002a9ec0fceaab15a83cfd692c5a5853db7444bbc2d43e4023));
	data[10] = Pairing.G1Point(uint256(0x0e219976ccd132d8105df6bb5d966e45960c6c0c89b1a813a13074c2e0eeddcf), uint256(0x21fd97d7d7a2685a285ae7a6d500a67c3b481cd58f30622dc471c8a322c9e8dc));
	data[11] = Pairing.G1Point(uint256(0x08ef7927d8ee4377f9ca9fb29c62b7c3b4b3318ffee39f6ff98049ba9c15093f), uint256(0x2aa27da2bf8655e4d0eb62593cd689e39d236e8f8317f9034d97ea8cd670172a));
	data[12] = Pairing.G1Point(uint256(0x10ebf3d053caf34c5bb5504718bb0c01240be7de39ca10e540af1c3716a1b54e), uint256(0x2953ec4092da24f6fdfc0f993dd8fc03535ba58372a392958d8661ef7755fa42));
	data[13] = Pairing.G1Point(uint256(0x04ebbce935346936a87d66df3e530c6289ea847ba6537c3135767ff5f673610e), uint256(0x2dee56755c83bad6e3664db6f59dbc755d05351bbbc0576aa4e4516fdd48b8e9));
	data[14] = Pairing.G1Point(uint256(0x2821f68bbbddeb404815f262678a12df3dc6fb4edbdfb32158a7559a939f79be), uint256(0x2fdefb21712e689a028ab10e33c9c59841580be7ba951aee8af4e49d3d5f7e25));
	data[15] = Pairing.G1Point(uint256(0x0015108a6490b9b34d2209b8732935fc70429f0dbaf48da6a53488eaf26520c0), uint256(0x12d8b396e81d39b07b0bd082c005f4bb7417311c9972817c9c457ec7d7f1fa10));
	data[16] = Pairing.G1Point(uint256(0x08f1366f6f2164c37fd84a6618dcd79dc7786ac45ede16e4d229369a4a82d9c1), uint256(0x05e1778a0507374f870bf9709a14f528bd7a7e0c06f518ff6ea8e9bd6b85b276));
	data[17] = Pairing.G1Point(uint256(0x04313ab89e06aa6465be938b046d226b3b8c676b7ca3d33c07f47bc69a9701e8), uint256(0x2f25d72b9902aa71e783c80d292dce12207921b1ca0cb95a4705fcc60d28feef));
	data[18] = Pairing.G1Point(uint256(0x1eea45401ad088cb137baea95ced84376ccab150de2a5aaf9337fa779d5d1ddd), uint256(0x0e566bb086ffa7ff69d74f0dde67cabaf7bd9e9358f3a75fc1fec575c7c36b94));
	data[19] = Pairing.G1Point(uint256(0x2e25041c0238a5a7ada9003fbe552ad970966d2b061f7261cf0fdbf111c4729c), uint256(0x0d0c80f6f0565145c7d93db7fc952e2f4029d362fa235ca9299e73ff89e8e7e9));
	data[20] = Pairing.G1Point(uint256(0x1689b97db28640aa012bd806ebb6f4510ac84af6b9a08a439c517acbdc036e56), uint256(0x035d70f6d26ec87b6038516ae59d053f193077d9806a212310552cd3c0e12332));
	data[21] = Pairing.G1Point(uint256(0x0a11386462a28911444d38079c27f159c7a8937ab3de2d9321907a3288f21282), uint256(0x02cfff757d016b8127e103a505b7208d2b118f92676c3bc2acd29c471d1e32cb));
	data[22] = Pairing.G1Point(uint256(0x1d89e542ccd000c6a986519c96d70d8d9a8431707990556984937e4e6035a8f1), uint256(0x12f74026ef46d7b32d3ea82224e3eba7eafdbd8c90c55aba69daaec666f43281));
	data[23] = Pairing.G1Point(uint256(0x06917f51869a0a45f60dc18891bf050618aa39e0620da6461fd6130bf44f0314), uint256(0x19b445c96cca14cbcba73e448b1acf30de115cac31ba9f813d54e052ff1dc0e8));
	data[24] = Pairing.G1Point(uint256(0x30420f4a0c135e43eb2ee14cbb1d12b703e356eb4010cb640afe0fbb7d7f6edd), uint256(0x20bf85dd70a5ca5a9f3858be5f1c40b420ef28f13c623fbf53f22cd77dc6c6f9));
	data[25] = Pairing.G1Point(uint256(0x10dee73cef9894b5bd1684b21a5b97b0bd2979aba8c5f2fe3d637f16caf71242), uint256(0x2fe9755c45e167282990dd3b3bfe693119a4d8eca49aa0ee92290f459cb8a14d));
	data[26] = Pairing.G1Point(uint256(0x27d99d0949efd844f3574ffcfa13dbcfcef118d17f371d4d121804fa3977b8f4), uint256(0x138978ab39c6c69c4bd93dc4af3b557d2f53c92d3e4ee628d69e4652d94296f0));
	data[27] = Pairing.G1Point(uint256(0x26721ec98da1121e2c03916be08a7aa26acf396803fdd53b022fa762f2b24816), uint256(0x1b292e1ae9d7cbdc66dca4e99a446f77f98cd67aad0ac2ff83e97c6dd36b0cf9));
	data[28] = Pairing.G1Point(uint256(0x19a198d9dd7ddf5e03d9f6adb1bf271d0488cd9eaa8622d8041aae4cd5692d55), uint256(0x2d94d13a742d2850acc67f1c81d296d06869af3696cf80384b84100b7dd81a06));
	data[29] = Pairing.G1Point(uint256(0x0e71a4d2dd9e28d2b69067ac56ae0c844340471c4b07585ff1d7a22389d7918d), uint256(0x1626df8a6325580c412c06652d46b6dd1f2035f05145e702264f652fc77a6bae));
	data[30] = Pairing.G1Point(uint256(0x232d20c33a771889aca70876532d9d072caf7c9e29873cf74b5c21ef2a4ed869), uint256(0x2d50b6f9df5d6bd965b0f2528d923e36db8b7afeb17f4d02ebc23b1ffb6c379a));
	data[31] = Pairing.G1Point(uint256(0x1e490e0be0262ea205d5dee45e26b1c33f78c5cc42d4b4fc60d70309baa34701), uint256(0x27aed75cb7b2ac20e00d881a767914d2206a733cddd8d4553198af588794433e));
	data[32] = Pairing.G1Point(uint256(0x00d92dd17736b9dfcdd8b16342775dcb0e99f77a7ef26dac54e42a9c0100b233), uint256(0x2db10f348593d3f93cca9e672cd408a66a31a9f55abfdea07f3a66d697179a1f));
	data[33] = Pairing.G1Point(uint256(0x1b44b3bebf77197c6d72862dee15fec9404c72df82b420a0ffc1802fddd11da4), uint256(0x30102f64c71df1c96e0ad4b87ebe9194836da8faec6f92674271a26ea6656be5));
	data[34] = Pairing.G1Point(uint256(0x27ff57f355c036783e661d9482a73a1f409dd92be98ea693e5659f69e111b4c2), uint256(0x2767e6a3c3a0c6b9fae9fd14c7f6f3652328fc39bb47836b3217c24f88cd4e47));
	data[35] = Pairing.G1Point(uint256(0x0bd9047ca068dc3b9ac359f26c3dde6b47e06c7ea6cda5fae4c554b8023bbbf9), uint256(0x16dae79a880dd897e67485348d8fd1482f096102c264767c03f0ac1429442496));
	data[36] = Pairing.G1Point(uint256(0x2219e4d05257a146b1ca75b1fdcfe67edc49088b13110dd608ff77c1e80f7237), uint256(0x268a2689e4c20c0aa34da6a07831a20751daf27f64c239cf3bd27889928440f3));
	data[37] = Pairing.G1Point(uint256(0x0a68bfb59dcc0fae9f0b77e35add9fa095fbff923ad310162a2a4e9a10b9ff59), uint256(0x22adb565251f358d9a4a06500aaae4f7861ad1f058e8ec6eae499db137372747));
	data[38] = Pairing.G1Point(uint256(0x0b3fedfbc7934e596bc706054439cca7c04e416d43449127f7cdbd632674a175), uint256(0x1e55e7b5716d7039c6bf3a2083559e34b015eda757d8cdfc2ba4a79d299aef50));
	data[39] = Pairing.G1Point(uint256(0x1b29af76e4091eee7ebb9e390b4cd620fe7a00701baa3c0fab5a21ff701c4bc6), uint256(0x1bab5e03421fa0862b2c0c1a63ce68840c8c9649929d8cea16dabab46a772d42));
	data[40] = Pairing.G1Point(uint256(0x302302aad6cf9239dc105126be988bd8a2db0eb162b1f4b117b478ceca17cdc1), uint256(0x0d20e3b7ca035c8d18036e6c6b8b0cc99e0ddc7ca7c27815752b9164c2620713));
	data[41] = Pairing.G1Point(uint256(0x0cbc43063f1a99110295d7fc402a4696b12ab0e6142494c416e084c7cf040d6e), uint256(0x0a94af3ee9e3630003a2d631c4347538e435a214d6fcbfdb84932a73579f02ad));
	data[42] = Pairing.G1Point(uint256(0x0499645081cf4900a3473e4ae9b5aaba5e5145d1b8bd5e0ce5b6f8723fc3e3bb), uint256(0x2482e3655f45438477a6513df403af7a750ffedd01e1a976d6da6ad0043ceaae));
	data[43] = Pairing.G1Point(uint256(0x03686072774010554f75176978159299e75d0df3107126f593ca8899581b4b23), uint256(0x0c5f5f5e4f748ad2770615c16c7545d3a66377f36654f9f5c0b6549b14db7d36));
	data[44] = Pairing.G1Point(uint256(0x11428e3b3b9d73086f7ed2b2b9e65b467b434dc1d4f5a298023216a8eec27bdc), uint256(0x2c2d290cb01b83fab9cf62f16742643cabed8801ac6faf470b21711509a2ba5c));
	data[45] = Pairing.G1Point(uint256(0x08ad6cb1c25e60fb7e912cb649d99292e9f55730d5554a5bab11973638cc7ac0), uint256(0x0e8832d61ac7e203ccad1c27135995480449feac2d153e71dd11aa008bffde51));
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
       vk.alpha = Pairing.G1Point(uint256(0x1042537b354e0881912f5fbd9ba6c79e9f3aca25194218a65e0fb078cc7ba958), uint256(0x13ecbe42c0759a465b14f3b53e9695e9152f3b8451bbb87ea90af9b93c38667d));
    vk.beta = Pairing.G2Point([uint256(0x202fbcb47d173153084bfe2c1d3ebf8b8c79304a075997f9c72ff67dc260c751), uint256(0x22feb927a985e719f51ac82f367559e9f2041fb95da28770f1dd88821291d43d)], [uint256(0x0adf15351d2cfe7143a1c804cecc9560d0580c27703e187769bc180861bbdf7d), uint256(0x0ec93542a320672143a0b52dec1a52f066ea5fd6780173c88d48dd99bf6e4d56)]);
    vk.gamma = Pairing.G2Point([uint256(0x2e7d851d6b2c2595e6ede3b7e006c8b005a3b38f7183857738e45d232aca7d6f), uint256(0x3059a6ac4e17f6b497597dbbdc5808207278dc9f8d0791b4eb4dad38e8aee455)], [uint256(0x11575572ec349c97a58976ff0ca5fe18040368aa48e8ac4141ffa5c7e5c8e740), uint256(0x06240efad42d81bf1c22538731429298085a9cd29586d2be88d5878affaedc72)]);
    vk.delta = Pairing.G2Point([uint256(0x176c0b9292975d1f5f903a2d6bebd3ea3d7c947207239295d2e6255d99259b21), uint256(0x24dff41d0427509d107e73d462105ad50cc8ca906a12ee4add6f102cb4465195)], [uint256(0x2251d35bfb8a5d2af25e67d50c147ec1e38d430513d40872f9d2e30bec8ac810), uint256(0x22faef6176b8403a0d138ad0ccb57a8cef835ed3c4c4cdf415e6027fd591af74)]);
    vk.gamma_abc0 = Pairing.G1Point(uint256(0x0bf6ac385ea977265a3d85597143f2bb000046d6e2ca5a3e673e937bad2eadec), uint256(0x11a17dbf09fe68c86aae5f76bdd413c4493ae1ab8148ff2c24b35aa6a6298ffa));
    }
    
    function verify(uint32[] memory input1, Proof memory proof) internal view returns (uint) {
        //uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        uint x;
        uint y;
        (x, y) = GetVK200.getvk(vk_x.X, vk_x.Y,input1);
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
            uint[2] memory c, uint32[46] memory input
        ) public returns (bool r) {
        Proof memory proof;
        proof.a = Pairing.G1Point(a[0], a[1]);
        proof.b = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.c = Pairing.G1Point(c[0], c[1]);
        uint32[] memory inputValues1 = new uint32[](46);
      
        for(uint i = 0; i < 46; i++){
            inputValues1[i] = input[i];
        }
        
        if (verify(inputValues1,proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}

