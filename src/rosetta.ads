with Ada.Strings.Text_Buffers;

package Rosetta is

   --  A mathematical description of a rosetta (specifically, a hypotrochoid).
   --  formed by tracing a point attached to a circle rolling inside another circle.
   type Hypotrochoid is record
      Outer_Radius : Float;     -- Radius of the fixed outer circle.
      Inner_Radius : Float;     -- Radius of the rolling inner circle.
      Pen_Offset   : Float;     -- From the center of the inner circle to the drawing point.
      Steps        : Positive;  -- Number of steps (points) used to approximate the curve.
   end record;

   --  A 2D coordinate in Cartesian space.
   type Coordinate is record
      X_Coord, Y_Coord : Float;
   end record
     with Put_Image => Put_Image_Coordinate;

   --  Redefines the 'Image attribute for Coordinate.
   procedure Put_Image_Coordinate (Output : in out Ada.Strings.Text_Buffers.Root_Buffer_Type'Class;
                                   Value  : Coordinate);

   --  A type for an unconstrained array of 2D points forming a curve.
   --  The actual bounds are set when an array object of this type is declared.
   type Coordinate_Array is array (Natural range <>) of Coordinate;

   --  Computes the coordinates of the rosetta curve defined by Curve (a hypotrochoid).
   --  Returns a centered array of coordinates.
   function Compute_Points (Curve : Hypotrochoid) return Coordinate_Array;

end Rosetta;
