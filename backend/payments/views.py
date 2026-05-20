from django.utils import timezone
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from users.models import HelpRequest
from .models import Transaction, HelpRequestEarnings, CommunityPool
from .serializers import (
    CheckoutSerializer, TipSerializer,
    PoolContributeSerializer, EarningsSerializer,
    CommunityPoolSerializer, TransactionSerializer,
)


def _upsert_earnings(helper, amount, fee, net, is_tip=False):
    """Add amounts to the helper's monthly earnings bucket."""
    now = timezone.now()
    obj, _ = HelpRequestEarnings.objects.get_or_create(
        helper=helper, year=now.year, month=now.month,
        defaults={'total_gross': 0, 'total_fees': 0, 'total_net': 0, 'total_tips': 0}
    )
    obj.total_gross   += amount
    obj.total_fees    += fee
    obj.total_net     += net
    if is_tip:
        obj.total_tips += amount
    else:
        obj.session_count += 1
    obj.save()


# ──────────────────────────────────────────────
#  POST /api/payments/checkout/
# ──────────────────────────────────────────────
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def checkout(request):
    """Create a held transaction (Stripe PaymentIntent would go here)."""
    ser = CheckoutSerializer(data=request.data)
    if not ser.is_valid():
        return Response(ser.errors, status=status.HTTP_400_BAD_REQUEST)

    d = ser.validated_data
    try:
        help_req = HelpRequest.objects.get(id=d['help_request_id'])
    except HelpRequest.DoesNotExist:
        return Response({'detail': 'HelpRequest not found.'}, status=404)

    if help_req.newcomer != request.user:
        return Response({'detail': 'Only the newcomer can pay.'}, status=403)

    if help_req.status not in (HelpRequest.Status.ACCEPTED,):
        return Response({'detail': 'Request must be accepted before payment.'}, status=400)

    # TODO: create real Stripe PaymentIntent here
    # intent = stripe.PaymentIntent.create(amount=int(d['amount']*100), currency='eur')

    txn = Transaction.objects.create(
        payer=request.user,
        payee=help_req.helper,
        amount=d['amount'],
        type=Transaction.Type.BOOKING,
        status=Transaction.Status.HELD,
        help_request=help_req,
        note=d.get('note', ''),
        stripe_payment_intent_id='pi_mock_' + str(help_req.id),  # replace with real intent.id
    )
    return Response(TransactionSerializer(txn).data, status=201)


# ──────────────────────────────────────────────
#  POST /api/payments/release/<request_id>/
# ──────────────────────────────────────────────
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def release(request, request_id):
    """Release escrow after HelpRequest → done."""
    try:
        help_req = HelpRequest.objects.get(id=request_id)
    except HelpRequest.DoesNotExist:
        return Response({'detail': 'Not found.'}, status=404)

    if request.user not in (help_req.newcomer, help_req.helper):
        return Response({'detail': 'Not authorised.'}, status=403)

    if help_req.status != HelpRequest.Status.DONE:
        return Response({'detail': 'Request must be marked done first.'}, status=400)

    txn = (
        Transaction.objects
        .filter(help_request=help_req, type=Transaction.Type.BOOKING, status=Transaction.Status.HELD)
        .first()
    )
    if not txn:
        return Response({'detail': 'No held transaction found.'}, status=404)

    txn.status = Transaction.Status.RELEASED
    txn.save()

    # Update helper earnings
    if txn.payee:
        _upsert_earnings(txn.payee, txn.amount, txn.platform_fee, txn.net_amount)
        txn.payee.total_sessions = (txn.payee.total_sessions or 0) + 1
        txn.payee.save(update_fields=['total_sessions'])

    return Response(TransactionSerializer(txn).data)


# ──────────────────────────────────────────────
#  POST /api/payments/tip/
# ──────────────────────────────────────────────
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_tip(request):
    ser = TipSerializer(data=request.data)
    if not ser.is_valid():
        return Response(ser.errors, status=400)

    d = ser.validated_data
    try:
        help_req = HelpRequest.objects.get(id=d['help_request_id'])
    except HelpRequest.DoesNotExist:
        return Response({'detail': 'Not found.'}, status=404)

    if help_req.status != HelpRequest.Status.DONE:
        return Response({'detail': 'Can only tip completed sessions.'}, status=400)

    txn = Transaction.objects.create(
        payer=request.user,
        payee=help_req.helper,
        amount=d['amount'],
        type=Transaction.Type.TIP,
        status=Transaction.Status.PAID,
        help_request=help_req,
    )

    if txn.payee:
        _upsert_earnings(txn.payee, txn.amount, txn.platform_fee, txn.net_amount, is_tip=True)

    return Response(TransactionSerializer(txn).data, status=201)


# ──────────────────────────────────────────────
#  POST /api/payments/pool/contribute/
# ──────────────────────────────────────────────
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def pool_contribute(request):
    ser = PoolContributeSerializer(data=request.data)
    if not ser.is_valid():
        return Response(ser.errors, status=400)

    d = ser.validated_data
    txn = Transaction.objects.create(
        payer=request.user,
        payee=None,
        amount=d['amount'],
        type=Transaction.Type.POOL,
        status=Transaction.Status.PAID,
        note=d.get('note', ''),
    )

    pool, _ = CommunityPool.objects.get_or_create(id=1)
    pool.balance       += txn.net_amount
    pool.total_donated += d['amount']
    pool.save()

    return Response(
        {'transaction': TransactionSerializer(txn).data, 'pool': CommunityPoolSerializer(pool).data},
        status=201,
    )


# ──────────────────────────────────────────────
#  GET /api/payments/earnings/
# ──────────────────────────────────────────────
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def earnings(request):
    """Return helper's monthly earnings history."""
    if not request.user.is_helper:
        return Response({'detail': 'Helper only.'}, status=403)

    qs = HelpRequestEarnings.objects.filter(helper=request.user)
    return Response(EarningsSerializer(qs, many=True).data)


# ──────────────────────────────────────────────
#  GET /api/payments/pool/
# ──────────────────────────────────────────────
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def pool_info(request):
    pool, _ = CommunityPool.objects.get_or_create(id=1)
    return Response(CommunityPoolSerializer(pool).data)