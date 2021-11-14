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
        Pairing.G1Point[] memory data = new Pairing.G1Point[](40);
        data[0] = Pairing.G1Point(uint256(0x11dbf23e34592274b345c5fba6162afb76fd8ea5ef9f71bbf98f5be14f3a01c4), uint256(0x02a036e7ead775540e77af419fc5be807798be888ad77f67a6a5ce4b02a40868));
data[1] = Pairing.G1Point(uint256(0x2b52477cfae2c3ad208d00aa94018f4b8aa31291b65aece2bf17fbd26f558311), uint256(0x0de3661d182a2c74e68441063b4966899f8e917861b516b5a55c46682e5803a2));
data[2] = Pairing.G1Point(uint256(0x134c8d6e6c3f46af1261d77bf48824ee164c18b503be46c37fb55d28be893faf), uint256(0x0e90bf8e0a78ffaeaf8b481188ba61186fade9b30bbd208606efc70ba3282b4d));
data[3] = Pairing.G1Point(uint256(0x2713106f35f4b8fd898f51d7f7aca7310a54294ee15034d79bfcb0dd14d96f64), uint256(0x0c54d10b1c7abec3638b3ff3aaad49d1404042fb3f76915e8c4cb5db27f0e524));
data[4] = Pairing.G1Point(uint256(0x0bd9389f254b264de2c31e9db9bcb87d8f211e940eb9c9a37db7b8bb8f8cce2c), uint256(0x09b7a07c6fff7502e44e0da3849492ae0bbb8090e5d18d5cab07f12ef2c93ca2));
data[5] = Pairing.G1Point(uint256(0x174efb471021499fa38c8b9d42c67426e36cec475bc80ffef3590bae9b4bc059), uint256(0x1eeadec5b70f6043b515a0d5573a5c1acd42659874749355c3fc60a39ba23b4f));
data[6] = Pairing.G1Point(uint256(0x1c0a6bd4b65c7cc8724c7b9ca4bcc1f64006ec942a29c72f286c73cc3507ff79), uint256(0x20807848e4b15ed9aa0ec11f99ae36eed364687af6dffdb2a3aab31d595369eb));
data[7] = Pairing.G1Point(uint256(0x266d318d86785bd6ffde3a823b8b040956236e1a036b310f0c17e047612448f4), uint256(0x0030a316d152897071d9a40d69465d204ba26a9dabe7f42b8989d982d26a3cf8));
data[8] = Pairing.G1Point(uint256(0x1806aa4d9b3da247b2a0e4820762ea85190f284a682ec2962b4546c45721cadf), uint256(0x0574f69a5661b407674a29aa395624c73c727d3e827b3ec7dfeed24f573e5b17));
data[9] = Pairing.G1Point(uint256(0x025f3eae96e9fb03266c06ef7443590526985f8fe08955a1fa537a7819aff3b3), uint256(0x183650db40bd3c23f57a729f018990812b81d1673c17bb55f8cbf78c8004b036));
data[10] = Pairing.G1Point(uint256(0x10a91c202ec9fa00e9f4b373f14595a3ac581c421d8b2002a3c6c6eb82e91741), uint256(0x0647cbcb4074a511760ca9aa10601e5f8bfb2a3f28e22b121095131e03310c29));
data[11] = Pairing.G1Point(uint256(0x072ba27b7fe3a75bbe2faa0e9aa87eda1a7266b5a6488ea4949d51a90b1c3fc1), uint256(0x09eae56c4e56d4e1e547c96ebcf720714dc0d79b99a5290d6a42b68e128aa1bf));
data[12] = Pairing.G1Point(uint256(0x1397e2285fa2728a74a319b0aefa62618daffc441d5cf3b465747bfb7838142d), uint256(0x0a158c8b762e436ce880c88e3586456face74533f14f6e1d46a0fe2d7c033cb4));
data[13] = Pairing.G1Point(uint256(0x11a5effc62b569d8d8c96d325c6b8fb6f2d36a38dc14e03ff3da3089af73efb6), uint256(0x3045aa1e575836d60150b85a70fb0eb8afedf7a04192d89da52a884637091a59));
data[14] = Pairing.G1Point(uint256(0x1d08f506727fa735ee74e6a025dce39b39786178ef3ef63d360ff56dce1205a6), uint256(0x04cd9970072f2fddc4ae51de171eee463d4f76618d1bf214f565806ea7b19d46));
data[15] = Pairing.G1Point(uint256(0x0592a26bc525f751ec0dca4966a2b63979166d6102c4a5a0194d81495e72dcb3), uint256(0x12ce670de856736e6510b68c45e7131af8d53fab2feb20882dad1bd51105b8ef));
data[16] = Pairing.G1Point(uint256(0x19cf29b1bbf291ed7ede65dbfa44d0b25b157eb00092033b3dab72e40b222dbc), uint256(0x0481fb0e2905597d57214bdfff82a8935217803120466182d776e1106f2bc589));
data[17] = Pairing.G1Point(uint256(0x03f3deb7ca6344eb63d7a37804a059f89c023b193be6f58ec30f1d470483c865), uint256(0x036afecef669a21bb17362defdd38f114fbdee858f510faa8d60b186b470f8ae));
data[18] = Pairing.G1Point(uint256(0x022c1e01553fc181d05d5069e29986fe1b77c3addb3dcf2bf3f51f7184484b4f), uint256(0x2ffe992cbc8ff65d3a98674bfbb6a21e1fed4ed422236a4a5f438781181c6231));
data[19] = Pairing.G1Point(uint256(0x0ee61173d455f473b44031c62b6d3e1bcf0c71068ea8de900e24924547214e33), uint256(0x0189a3fa5fd2b6da3c0516cc61059b9710606f9120bcdd9c75165f5fdaf60b99));
data[20] = Pairing.G1Point(uint256(0x12ce3864b44d4f0d09ad06dcd55b78e7a360a117d5e54dbe3f7dd2ae68d8fa5b), uint256(0x13d27aeff4c8ad9732af5b868183b76589761cb17783484baa9860965bc37e56));
data[21] = Pairing.G1Point(uint256(0x19463af1683fe5367328f113af29663e5db56ae09bad84028d7bae7c52380cd1), uint256(0x1cfcf16d01ccc58599695d359e38a06d0c2d9613a944623e773ec437ba965e47));
data[22] = Pairing.G1Point(uint256(0x0b65f41865b7e9c2bd2d0ad1e9d199ac30e1a701edb75839d2145fa54522b913), uint256(0x15d6d98079267b16c2b2298001381429886c6b3115be4d6dad50c6c3c7da7dca));
data[23] = Pairing.G1Point(uint256(0x2e0068e9e0f6347c9831d74e09638bb0976b6e99f60f65343b37ed66973662a2), uint256(0x037212fbe3203a416742dc9bbd65b801663731f01407620b900e540515e49cb9));
data[24] = Pairing.G1Point(uint256(0x2d1e44247ad53107c6e6e43ee7e521850536349861328bd23608f081e8cb5cec), uint256(0x1f8b06e38f459521f1f296b8210a54fcf976e7c324380612fef8275f3280bc89));
data[25] = Pairing.G1Point(uint256(0x0771a013e9361b90feb496c5302ea1bfff0712707d3a51c533194314fdf642f5), uint256(0x29d83864892dde433bfd03c0b08a4d85cb739e1465f4fd87977cd9a0e6c64666));
data[26] = Pairing.G1Point(uint256(0x24661ddac37d03c51ad295efd86eb3cdfb5cea7a41ae1b1c0565838eecff45d1), uint256(0x0f22ed03b34298795d66aabc32c07ae1d7265a1d21d0957cc820b18156a8fb7b));
data[27] = Pairing.G1Point(uint256(0x05d2ff4801a8fda49498b970140251dfa92713818042d8baf50b94d5f97a4199), uint256(0x2e7216a5a0fa12da56a0776c9b1b595efe19c74792b0cc467a96c1184db01c08));
data[28] = Pairing.G1Point(uint256(0x232bb4c7a957a62f27e8ffaa93911f13efee1920ed467441c196b8dc50209c5a), uint256(0x2fa44b8b9031f47ce09088106381397c0ccbb22e889ff6564a6348fa3fc318c6));
data[29] = Pairing.G1Point(uint256(0x0748b6dce47bdaf3f9368de3d01370ee5619541dda4186be44e016c85984d8e2), uint256(0x272d886f75f4508682589420e48016f22c007505f2d3648f7ba90468fa7355d5));
data[30] = Pairing.G1Point(uint256(0x2cea01ad189e29a8770a72d92032e4642b55b7df4aabec7a031e02a3e1010200), uint256(0x195b16062862d6f77ac207a5bea4c708f5ffd4e770fdca0ccd37998c606913bd));
data[31] = Pairing.G1Point(uint256(0x28264b870d514db9c47f7b885b39f8303375ff4ac92dbe8849e310b49ffc0718), uint256(0x0b21e7f16b13c5030a2fd4dc69906b827296b7da0ec1495b9f3d3af5aba6ef19));
data[32] = Pairing.G1Point(uint256(0x27f181bb56d9c4fdd674f718d3e54c58af2fdff98a9f28402fa9195e66f5f94e), uint256(0x146c7a7f66a00e449988b6c6372950dab9997ee08af48fdce6ca3235fa06dd1d));
data[33] = Pairing.G1Point(uint256(0x182642ff4f77554a3efc6dd08f382a76d57cfd8a978b63859e924221afbb14fd), uint256(0x1982c8f5f8aae505f7cd14f5e7e7732ab2d3eb5a0b797c508b6ff1ce00d57c9f));
data[34] = Pairing.G1Point(uint256(0x11192e6cd636b70f32195dda213ebe705a1f4e0ec56c853208e14330738cbcb6), uint256(0x138548f91a3dbc15ac2c7f00eca13b0f4dd574ddf788f8e637c50d8165c1a9d8));
data[35] = Pairing.G1Point(uint256(0x2790c5d01f0900fd15ec129846bf50cdb92559928718c92c94bb246e6d22f4b4), uint256(0x08f98516ec703094fe3f4445b8f626eddc269b1975040701171d25ee932ffed2));
data[36] = Pairing.G1Point(uint256(0x2d13e59480011781e2a7a73268f18bee391e2abaefdb5d6d3f274474ae4c0415), uint256(0x1991d3dcda3cdd73bb02b7d93b0e31b1a22123027eb827112a1e9e66acb522a4));
data[37] = Pairing.G1Point(uint256(0x172918ad758b21afe31098dfdc824a8f6be9428318e6dc23d811c31b2de395a7), uint256(0x265667a6eff62a047409ad1fee8f4a71c957edde718e3d0d744ea4e95c8d3c19));
data[38] = Pairing.G1Point(uint256(0x195344b439033ca2e40970f04ed9106357a7ffc7f95963403a2c991c951d0732), uint256(0x0e10e67ccd5ad1cc6ad4aa2608e9f35769386c7075800012e70dde9d474f8e37));
data[39] = Pairing.G1Point(uint256(0x03a293c53c9ce7a6244d2886ede4b4a7abfe9bbba6a096b2f80c4b5e9836642c), uint256(0x14b675e98b3da529d2e033f59963c2363097fcd01b3c07e610f1abd0a9ab637d));
        Pairing.G1Point memory vk_x1 = Pairing.G1Point(m1, n1);
        for (uint i = 0; i < iinput.length; i++) {
            vk_x1 = Pairing.addition(vk_x1, Pairing.scalar_mul(data[i], uint(iinput[i])));
        }
        return (vk_x1.X,vk_x1.Y);
    }
}




contract Verifier {
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
      vk.alpha = Pairing.G1Point(uint256(0x26396a0c0fc41cb9122bdc5290f87fbfa859125b9788cde829e77f8f33e36dbc), uint256(0x245bfddef4ce0a78a01cbdfe7a3d69133f407a09deb5fc666f49901c06db9d04));
vk.beta = Pairing.G2Point([uint256(0x03c26aae60641e9a10cb36837bfd9f4f957a3131514a7e48ebec61ed76922c56), uint256(0x22fc02661d467f11244c210a83984c6ac1e9eca93bb87e3a9919bcb64cc94098)], [uint256(0x24de56404a778ced0aa33e9dbdfef7eab322f0fc7b42d13b003e0d02ae0434f2), uint256(0x03b69e705db0b98af45dcb22228a15c0aaa8536790026bd3f4410b32854269cc)]);
vk.gamma = Pairing.G2Point([uint256(0x16a7f296a49498428784e0e1f314b9727a52a71ce91a427619436418786af264), uint256(0x1d8a298b2e535658ea31399fc20b805ecc7e2efe6e92a5a73775644a8f37083a)], [uint256(0x29c818efc0b266184e07ddc26cf6bf5cca3845581a1f00d52c076c9d6f4fa503), uint256(0x20b1b279c84b20863ac71cee655d57aa034eb1cc5681a1536e5593b0b68fbdcb)]);
vk.delta = Pairing.G2Point([uint256(0x1d84443defc8befd9a7edc06b82ac766a3e5f309b2dc4a6214e8bb571f7a4aa5), uint256(0x12527c318581b3a4b2fc3a0f641ef91daed75487aaa95c6aedf6a3d2f342d7fa)], [uint256(0x26eeac2f794448da0e9e393a2830f7c6d47949543d20ede51d8d74501f8f462b), uint256(0x17d4ebe19a8b536be5900338b3382bf348e8ed2992405e5baaafb9904a17ad97)]);
vk.gamma_abc0 = Pairing.G1Point(uint256(0x06f05dabc3854474de94bc19a3ee9954eda648170e96f6f6a319997862d0c058), uint256(0x1823513db32608b4af0fe981236371c62718717d47c16ac39fdcdf8419014edf));
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
            uint[2] memory c, uint32[40] memory input
        ) public returns (bool r) {
        Proof memory proof;
        proof.a = Pairing.G1Point(a[0], a[1]);
        proof.b = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.c = Pairing.G1Point(c[0], c[1]);
        uint32[] memory inputValues1 = new uint32[](40);
      
        for(uint i = 0; i < 40; i++){
            inputValues1[i] = input[i];
        }
        
        if (verify(inputValues1,proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}

