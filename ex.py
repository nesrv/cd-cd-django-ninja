
class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]



# Ninja
@api.get("/users", response=List[UserSchema], auth=ApiKey())
def list_users(request):
    return User.objects.all()